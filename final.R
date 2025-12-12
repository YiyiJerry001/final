library(tidyverse)
library(jsonlite)
library(sf)
library(tidycensus)
library(httr)
library(tmap)
library(purrr)

# --------------------------
# 1. 加载 CTA L 站点数据
# --------------------------
cta_l_url <- "https://data.cityofchicago.org/resource/6zsd-86xi.json"
cta_l_raw <- fromJSON(cta_l_url, flatten = TRUE)

cta_l <- cta_l_raw %>%
  mutate(
    longitude = map_dbl(location.coordinates, ~ if (length(.x) >= 1) .x[1] else NA_real_),
    latitude  = map_dbl(location.coordinates, ~ if (length(.x) >= 2) .x[2] else NA_real_)
  ) %>%
  filter(!is.na(longitude) & !is.na(latitude)) %>%  # 去掉缺失坐标的行
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326)

# --------------------------
# 2. 加载社区边界（这里仅作为底图，可选）
#    注意：这个 geojson 只有 geometry，没有社区名字等属性
# --------------------------
community_url <- "https://data.cityofchicago.org/resource/cauq-8yn6.geojson"
communities <- st_read(community_url)
communities <- st_transform(communities, crs = 4326)

# --------------------------
# 3. 下载带几何的 Census tract 数据（Cook County）
# --------------------------
year <- 2022
vars <- c(
  total_pop        = "B01003_001",
  median_income    = "B19013_001",
  poverty          = "B17020_002",
  poverty_denom    = "B17020_001",
  transit_commute  = "B08301_010",
  commute_total    = "B08301_001"
)

chi_census <- get_acs(
  geography = "tract",
  variables = vars,
  state = "IL",
  county = "Cook",
  geometry = TRUE,
  year = year
) %>%
  select(GEOID, variable, estimate, geometry) %>%
  st_transform(crs = 4326)

# --------------------------
# 4. 转为宽格式，并把 ACS 变量代码重命名为易读名字
# --------------------------
# 转为宽格式
chi_data <- chi_census %>%
  st_drop_geometry() %>%
  pivot_wider(names_from = variable, values_from = estimate)

# 查看 pivot_wider 后的列名，确认列名是否符合预期
colnames(chi_data)

# 确保 poverty_denom 列被保留
chi_data <- chi_data %>%
  select(GEOID, total_pop, median_income, poverty, poverty_denom, transit_commute, commute_total)

# --------------------------
# 5. 把 CTA 站点分配到各个 Census tract
# --------------------------
cta_tract <- st_join(cta_l, chi_census, join = st_within)

# --------------------------
# 6. 按 tract（GEOID）统计每个片区的站点数量
# --------------------------
cta_count_by_tract <- cta_tract %>%
  st_drop_geometry() %>%
  count(GEOID, name = "station_count")  # station_count 为每个 tract 的站点数

# --------------------------
# 7. 组装最终分析用数据：几何 + 社会经济变量 + 站点数
# --------------------------
# 先抽出每个 GEOID 的几何
tract_geo <- chi_census %>%
  select(GEOID, geometry) %>%
  distinct()

chi_tract_full <- tract_geo %>%
  left_join(chi_data, by = "GEOID") %>%
  left_join(cta_count_by_tract, by = "GEOID") %>%
  mutate(
    station_count = replace_na(station_count, 0),  # 没有站点的片区记为 0
    poverty_rate  = poverty / poverty_denom,  # 计算贫困率
    transit_share = transit_commute / commute_total  # 公共交通通勤比例
  )

# --------------------------
# 8. 用 tmap 可视化
# --------------------------
tmap_mode("view")  # 交互模式，可以缩放拖动

# (1) 每个 Census tract 的 CTA L 站点数量
tm_shape(chi_tract_full) +
  tm_borders() +
  tm_fill(col = "station_count",
          palette = "Blues",
          title = "CTA L 站点数量") +
  tm_layout(main.title = "Chicago 各 Census Tract 的 CTA L 站点数")

# (2) 每个 Census tract 的中位收入
tm_shape(chi_tract_full) +
  tm_borders() +
  tm_fill(col = "median_income",
          palette = "YlGnBu",
          title = "中位收入") +
  tm_layout(main.title = "芝加哥 Census Tract 的中位收入")
