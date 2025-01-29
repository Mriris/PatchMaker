import json
import geopandas as gpd

# 加载 GeoJSON 文件
geojson_file = r'D:\0Program\Datasets\241120\Compare\TEMP\JW\Result\R22.geojson'  # 替换为您的 GeoJSON 文件路径
gdf = gpd.read_file(geojson_file)

# 创建 Labelme_cd 格式的 JSON 文件结构
labelme_cd_data = {
    "version": "5.1.0",
    "flags": {},
    "shapes": [],
    "imagePath": "path_to_image.tif",  # 替换为您的图像路径
    "imageHeight": 1727,  # 替换为您的图像高度
    "imageWidth": 1984  # 替换为您的图像宽度
}

# 遍历 GeoJSON 中的每个多边形
for _, row in gdf.iterrows():
    shape = {
        "label": "change",  # 标签名称，可以自定义
        "points": [],
        "group_id": None,
        "shape_type": "polygon",
        "flags": {}
    }

    # 获取多边形的坐标点
    geom = row['geometry']
    if geom.geom_type == 'Polygon':
        for coord in geom.exterior.coords:
            shape["points"].append([coord[0], coord[1]])

    # 将每个多边形添加到 Labelme_cd 数据中
    labelme_cd_data["shapes"].append(shape)

# 保存为 Labelme_cd 格式的 JSON 文件
output_file = r'D:\0Program\Datasets\241120\Compare\TEMP\JW\LabelmeCD\label\J51.json'  # 输出文件路径
with open(output_file, 'w') as f:
    json.dump(labelme_cd_data, f, indent=4)

print(f"转换完成，文件已保存为 {output_file}")
