import os
import json
from shapely.geometry import shape, box, mapping

# 输入和输出路径
input_file = r"D:\0Program\Python\PatchMaker\Datasets\geo\output_bbox_expanded.geojson"
output_folder = r"D:\0Program\Python\PatchMaker\Datasets\geo\split"

# 检查并创建目标文件夹
if not os.path.exists(output_folder):
    os.makedirs(output_folder)

# 读取 GeoJSON 文件
with open(input_file, "r", encoding="utf-8") as f:
    data = json.load(f)

# 获取原始多边形
original_feature = data["features"][0]
polygon = shape(original_feature["geometry"])

# 获取边界框
minx, miny, maxx, maxy = polygon.bounds

# 计算中心点
mid_x = (minx + maxx) / 2
mid_y = (miny + maxy) / 2

# 创建四个子多边形
sub_polygons = [
    box(minx, mid_y, mid_x, maxy),  # 左上
    box(mid_x, mid_y, maxx, maxy),  # 右上
    box(minx, miny, mid_x, mid_y),  # 左下
    box(mid_x, miny, maxx, mid_y)   # 右下
]

# 保存每个子多边形为独立的 GeoJSON 文件
for i, sub_polygon in enumerate(sub_polygons):
    # 创建新的 Feature
    new_feature = {
        "type": "Feature",
        "properties": {"part": i + 1},  # 标识子区域编号
        "geometry": mapping(sub_polygon)
    }

    # 构建新的 GeoJSON 数据结构
    output_data = {
        "type": "FeatureCollection",
        "features": [new_feature]
    }

    # 保存为新的 GeoJSON 文件
    output_file = os.path.join(output_folder, f"split_part_{i+1}.geojson")
    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(output_data, f, ensure_ascii=False, indent=4)

    print(f"子多边形 {i+1} 已保存到 {output_file}")
