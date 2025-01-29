import ee
import geemap
# geemap.set_proxy(port=7890)
import os

from ipyleaflet import WidgetControl

os.environ['HTTP_PROXY'] = 'http://127.0.0.1:7890'
os.environ['HTTPS_PROXY'] = 'http://127.0.0.1:7890'
ee.Initialize()
# 1. 定义研究区边界，这里选择上海范围作为研究区
roi = ee.Geometry.Polygon([
    [[121.0, 31.5], [122.0, 31.5], [122.0, 30.8], [121.0, 30.8], [121.0, 31.5]]
])
# 2. 云掩膜函数,根据Sntinel-2的QA60波段去除云像元，需要注意的是该方法在2022年2月之后的数据中不再适用
def maskS2clouds(image):
    # 选择QA60波段，该波段用于云掩膜
    qa = image.select('QA60')
    # 创建云掩膜，使用 bitwise 操作，0 表示无云
    cloudMask = qa.bitwiseAnd(1 << 10).eq(0)  # 含有云的bit
    cirrusMask = qa.bitwiseAnd(1 << 11).eq(0)  # 含有卷云的bit
    # 掩膜云和卷云区域
    return image.updateMask(cloudMask).updateMask(cirrusMask)
# 3. 加载 Sentinel-2 Level 1C 数据集，筛选云量在20以下的影像，并应用云掩膜
sentinel2_TOA = ee.ImageCollection('COPERNICUS/S2') \
    .filterDate('2020-01-01', '2020-12-31') \
    .filterBounds(roi ) \
    .filter(ee.Filter.lt('CLOUDY_PIXEL_PERCENTAGE', 20)).map(maskS2clouds)
# 获取影像的日期列表
dates = sentinel2_TOA.aggregate_array('system:time_start').map(lambda time: ee.Date(time).format('YYYY-MM-dd')).distinct()
# 影像镶嵌
def mosaic_per_day(date):
    date = ee.Date(date)
    daily_images =sentinel2_TOA.filterDate(date, date.advance(1, 'day'))  # 获取这一天的影像
    mosaic = daily_images.mosaic()# 将当天的影像拼接
    return mosaic.set('system:time_start', date.millis())  # 保留日期属性
# 将每天拼接后的影像映射到新的 ImageCollection 中
sentinel2_TOA_mosaics = ee.ImageCollection(dates.map(mosaic_per_day))
# 选择目标影像进行可视化
target_image  = ee.Image(sentinel2_TOA_mosaics.toList(sentinel2_TOA_mosaics.size()).get(3))
# target_image =sentinel2_TOA_mosaics.end()  # 获取拼接后的第一天影像
#创建地图
Map = geemap.Map()
# 将第一张影像添加到地图中
Map.addLayer(target_image, {'bands': ['B4', 'B3', 'B2'], 'min': 0, 'max': 3000}, 'Mosaic for a Day')
Map.centerObject(roi , 8)
# 获取影像的日期并格式化为字符串
image_date = ee.Date(target_image.get('system:time_start')).format('YYYY-MM-dd').getInfo()
# 添加日期标注
Map.add_text(text=image_date, position='topleft', font_size=20, font_color='black')
#添加矩形框范围
Map.addLayer(roi , {}, 'Shanghai')
Map
Map(center=[31.15053499918049, 121.5000000000003], controls=(WidgetControl(options=['position', 'transparent'])))
from datetime import datetime
# 获取待导出影像的时间戳
timestamp = target_image.get('system:time_start').getInfo()

# 将时间戳转换为人类可读的日期格式
date = datetime.fromtimestamp(timestamp / 1000).strftime('%Y-%m-%d_%H-%M-%S')
# 设置导出任务
task = ee.batch.Export.image.toDrive(
    image=target_image,
    description=f'Sentinel2_L1_{date}',  # 文件名
    scale=30,  # 分辨率（单位：米）
    region=roi,  # 要导出的区域
    fileFormat='GeoTIFF'  # 文件格式
)
# 启动导出任务
task.start()