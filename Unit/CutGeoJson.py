import os
import json
from shapely.geometry import shape, box, mapping

# 加载原始 GeoJSON 文件
input_file = r"/home/iris/Datasets/JW1/Area/area2.geojson"
output_folder = r"/home/iris/Datasets/JW1/Area/split_parts/"

# 检查并创建目标文件夹
if not os.path.exists(output_folder):
    os.makedirs(output_folder)

with open(input_file, "r") as f:
    data = json.load(f)

# 获取多边形几何
original_feature = data["features"][0]
polygon = shape(original_feature["geometry"])

# 获取边界框
minx, miny, maxx, maxy = polygon.bounds

# 计算中点
mid_x = (minx + maxx) / 2
mid_y = (miny + maxy) / 2

# 按中心点将多边形分为 4 个子区域
sub_polygons = [
    box(minx, mid_y, mid_x, maxy),  # 左上
    box(mid_x, mid_y, maxx, maxy),  # 右上
    box(minx, miny, mid_x, mid_y),  # 左下
    box(mid_x, miny, maxx, mid_y)   # 右下
]

# 为每个子多边形创建单独的 GeoJSON 文件
for i, sub_polygon in enumerate(sub_polygons):
    # 构建子多边形的 Feature
    new_feature = {
        "type": "Feature",
        "properties": {**original_feature["properties"], "part": i + 1},  # 添加分区标识
        "geometry": mapping(sub_polygon)  # 转换为 GeoJSON 格式
    }

    # 构建单独的 GeoJSON 数据
    output_data = {
        "type": "FeatureCollection",
        "name": f"{data['name']}_part_{i+1}",
        "crs": data["crs"],
        "features": [new_feature]
    }

    # 保存到单独的文件
    output_file = f"{output_folder}split_part_{i+1}.geojson"
    with open(output_file, "w") as f:
        json.dump(output_data, f, indent=4)

    print(f"子多边形 {i+1} 已保存到 {output_file}")
