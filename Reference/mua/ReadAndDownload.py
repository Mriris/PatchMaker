import datetime
import rasterio
import ee
import geemap

# 初始化 Google Earth Engine
service_account = 'service-account@test1-447007.iam.gserviceaccount.com'
key_file = '../../Personal/test1-447007-3fb4b19a28e7.json'
credentials = ee.ServiceAccountCredentials(service_account, key_file)
ee.Initialize(credentials)

print("Google Earth Engine 已成功初始化！")

# 读取 GeoTIFF 文件
tif_file = r"/intput/549596_257631.tif"
with rasterio.open(tif_file) as src:
    bounds = src.bounds
    crs = src.crs

print("GeoTIFF 文件信息：")
print("范围（bounds）：", bounds)
print("坐标参考系（CRS）：", crs)

# 转换 AOI 坐标
if crs.to_epsg() != 4326:
    from pyproj import Transformer
    transformer = Transformer.from_crs(crs, "EPSG:4326", always_xy=True)
    min_lon, min_lat = transformer.transform(bounds.left, bounds.bottom)
    max_lon, max_lat = transformer.transform(bounds.right, bounds.top)
else:
    min_lon, min_lat, max_lon, max_lat = bounds.left, bounds.bottom, bounds.right, bounds.top

aoi = ee.Geometry.Rectangle([min_lon, min_lat, max_lon, max_lat])
print("AOI 范围 (WGS84):", [min_lon, min_lat, max_lon, max_lat])

# 时间和影像筛选
start_date = '2023-10-01'
end_date = '2023-11-30'
target_date = datetime.datetime(2023, 10, 30)
target_timestamp = int(target_date.timestamp() * 1000)

dataset = ee.ImageCollection('COPERNICUS/S2_HARMONIZED') \
    .filterDate(start_date, end_date) \
    .filterBounds(aoi)

def add_time_difference(image):
    time_diff = ee.Number(image.date().millis()).subtract(target_timestamp).abs()
    return image.set('time_difference', time_diff)

dataset = dataset.map(add_time_difference).sort('time_difference')
image = dataset.first()

# 打印影像范围
if image:
    print("影像范围:", image.geometry().getInfo())
else:
    print("未找到符合条件的影像。")
    exit(1)

# 计算 AOI 和影像交集
intersection = aoi.intersection(image.geometry(), maxError=1)
print("交集范围 (GeoJSON):", intersection.getInfo())

# 检查交集是否为空
intersection_size = ee.FeatureCollection(intersection).size().getInfo()
if intersection_size == 0:
    print("AOI 和影像范围没有交集。")
    exit(1)

# 裁剪影像
clipped_image = image.clip(intersection)

# 导出影像
output_file = r'D:\0Program\Python\PatchMaker\outputs\image_7.tif'
geemap.ee_export_image(
    ee_object=clipped_image,
    filename=output_file,
    scale=30,
    region=intersection.getInfo()['coordinates'],
    crs='EPSG:4326'
)
print(f"影像已成功导出为 {output_file}")
