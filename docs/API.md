# 数据源接口说明

## 1. 美国 NWS 警报（实时）
```
GET https://api.weather.gov/alerts/active?event=Tornado%20Warning&status=actual
Headers: User-Agent: <你的应用名> (联系方式)
```
- 返回 GeoJSON FeatureCollection，`features[].properties` 含 `headline/areaDesc/severity/onset/ends/areaDesc`
- 免 API Key；频率建议 ≤ 5 次/秒
- **不支持 `limit` 参数**（会 400），分页用 `cursor`
- 覆盖范围仅美国及其属地

常用参数：`event`（可多值）、`area`（州/县代码）、`status=actual`、`severity`、`format`

## 2. SPC 逐日龙卷报告（CSV）
```
GET https://www.spc.noaa.gov/climo/reports/260101_rpts_torn.csv
```
格式：`Time,F_Scale,Location,County,State,Lat,Lon,Comments`

其它：
- 今日：`today_torn.csv`、近3小时：`last3hours_torn.csv`、昨日：`yesterday_torn.csv`
- 全美当年聚合（较慢）：遍历 365 个日文件后合并
- 历史年鉴：`https://www.spc.noaa.gov/wcm/data/1950-2025_actual_tornadoes.csv`

> `F_Scale` 在初步报告里多为 `UNK`，强度需等 NCEI Storm Events 正式核定。

## 3. SPC 展望（GeoJSON）
```
https://www.spc.noaa.gov/products/outlook/day1otlk_cat.lyr.geojson   # 风险等级 TSTM/MRGL/SLGT/ENH/MDT/HIGH
https://www.spc.noaa.gov/products/outlook/day1otlk_torn.lyr.geojson  # 龙卷概率 LABEL 形如 "10% All Areas"
```
Day1/2/3 都有，替换 `day1` 为 `day2`/`day3`。

## 4. 巴西 INMET（强对流/暴雨）
```
GET https://apiprevmet3.inmet.gov.br/avisos/ativos
Headers: User-Agent: <必须带，否则连接被重置>
```
返回结构：
```json
{"hoje":[ ... ], "futuro":[ ... ], "riscos":[ ... ], "instrucoes":[ ... ]}
```
单条记录关键字段：`id_aviso`, `severidade`（`Grande Perigo`/`Perigo`/`Perigo Potencial`）、`data_inicio`, `data_fim`, `regioes`（`Sul,Sudeste,...`）、`municipios`、`poligono`

> 注意：INMET 不提供“龙卷”类别，只有暴雨/强风/冰雹等级。

## 5. 其它参考
- 加拿大：ECCC / Northern Tornadoes Project（https://www.uwo.ca/ntp/）
- 欧洲：ESSL / ESWD
- 历史：NCEI Storm Events Database
