#无效
import datetime
import ee
import geemap

# 初始化 Google Earth Engine
service_account = 'service-account@test1-447007.iam.gserviceaccount.com'
key_file = '../Personal/test1-447007-3fb4b19a28e7.json'
credentials = ee.ServiceAccountCredentials(service_account, key_file)
ee.Initialize(credentials)

print("Google Earth Engine 已成功初始化！")

# 定义感兴趣区域 (AOI)，设置 geodesic=False
aoi = ee.Geometry.Rectangle(
    coords=[290851.857, 3774117.121, 317131.857, 3797149.121],
    proj='EPSG:32649',
    geodesic=False
)

# 将 AOI 转换为地理坐标系 EPSG:4326，添加 maxError 参数
aoi_transformed = aoi.transform('EPSG:4326', maxError=1)

# 目标日期（2023-10-30）的时间戳（毫秒）
target_date = datetime.datetime(2023, 10, 30)
target_timestamp = int(target_date.timestamp() * 1000)

# 筛选 Sentinel-2 数据集
dataset = ee.ImageCollection('COPERNICUS/S2_HARMONIZED') \
    .filterDate('2023-10-01', '2023-11-30') \
    .filterBounds(aoi_transformed)

# 添加一个属性，表示与目标日期的时间差
def add_time_difference(image):
    time_diff = ee.Number(image.date().millis()).subtract(target_timestamp).abs()
    return image.set('time_difference', time_diff)

dataset = dataset.map(add_time_difference).sort('time_difference')

# 获取离目标时间最近的影像
image = dataset.first()

# 检查 AOI 和影像范围是否匹配
print("AOI 范围 (GeoJSON):", aoi_transformed.getInfo())
if image:
    print("影像范围 (GeoJSON):", image.geometry().getInfo())

# 扩大 AOI 的范围（单位为米，假设扩大 1000 米）
expanded_aoi = aoi.buffer(1000, maxError=1)

print("扩大后的 AOI 范围 (GeoJSON):", expanded_aoi.getInfo())

# 使用扩大后的 AOI 进行裁剪
if image:
    clipped_image = image.clip(expanded_aoi).updateMask(image.select(0).gt(0))

    # 导出影像
    output_file = r'D:\0Program\Python\PatchMaker\outputs\closest_to_20231030_11.tif'
    geemap.ee_export_image(
        ee_object=clipped_image,
        filename=output_file,
        scale=50,
        region=expanded_aoi.getInfo()['coordinates'],  # 使用扩大后的 AOI
        crs='EPSG:4326'
    )
    print(f"影像已成功导出为 {output_file}")

