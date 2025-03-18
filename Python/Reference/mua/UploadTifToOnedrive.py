#有大范围空白
import datetime
import ee

# 初始化 Google Earth Engine
service_account = 'service-account@test1-447007.iam.gserviceaccount.com'
key_file = '../../Personal/test1-447007-3fb4b19a28e7.json'
credentials = ee.ServiceAccountCredentials(service_account, key_file)
ee.Initialize(credentials)

print("Google Earth Engine 已成功初始化！")

# 定义感兴趣区域 (AOI)，设置 geodesic=False
aoi = ee.Geometry.Rectangle(
    coords=[290851.857, 3774117.121, 317131.857, 3797149.121],
    proj='EPSG:32649',
    geodesic=False
)

# 目标日期（2023-10-30）的时间戳（毫秒）
target_date = datetime.datetime(2023, 10, 30)
target_timestamp = int(target_date.timestamp() * 1000)

# 筛选 Sentinel-2 数据集
dataset = ee.ImageCollection('COPERNICUS/S2_HARMONIZED') \
    .filterDate('2023-10-01', '2023-11-30') \
    .filterBounds(aoi)

# 添加一个属性，表示与目标日期的时间差
def add_time_difference(image):
    time_diff = ee.Number(image.date().millis()).subtract(target_timestamp).abs()
    return image.set('time_difference', time_diff)

dataset = dataset.map(add_time_difference).sort('time_difference')  # 按时间差排序

# 获取离目标时间最近的影像
image = dataset.first()

# 打印影像元数据
if image:
    image_info = image.getInfo()
    timestamp = image_info['properties']['system:time_start']
    readable_time = datetime.datetime.fromtimestamp(timestamp / 1000, datetime.timezone.utc).strftime('%Y-%m-%d %H:%M:%S')

    print("选定影像元数据：")
    print("ID:", image_info['id'])
    print("时间:", readable_time)
    print("云覆盖率:", image_info['properties']['CLOUDY_PIXEL_PERCENTAGE'])
else:
    print("未找到符合条件的影像。")

# 导出影像到 Google Drive
if image:
    # 裁剪影像到感兴趣区域
    clipped_image = image.clip(aoi).toUint16()  # 将波段数据类型统一为 UInt16

    # 转换 AOI 到地理坐标系 (EPSG:4326)
    region = aoi.transform('EPSG:4326', 1).getInfo()['coordinates']  # 确保区域使用地理坐标系

    task = ee.batch.Export.image.toDrive(
        image=clipped_image,  # 使用裁剪后的影像
        description='Export closest_to_20231030_2',
        folder='EarthEngineExports',  # Google Drive 中的文件夹名称
        fileNamePrefix='closest_to_20231030_2',  # 导出的文件名前缀
        scale=8,  # 导出的分辨率
        region=region,  # 导出区域
        crs='EPSG:4326'  # 保留地理坐标系
    )
    task.start()
    print("影像导出任务已提交到 Google Drive，请稍后检查您的 Drive 文件夹。")
