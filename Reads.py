import os
import rasterio
import json
from shapely.geometry import box, mapping
from rasterio.warp import transform_bounds

# 设置输入文件夹路径和输出文件夹路径
input_dir = r"C:\0Program\Datasets\241120\Compare\Datas\out"  # 输入文件夹（包含多个TIF文件）
output_dir = r"C:\0Program\Datasets\241120\Compare\Datas\geo"  # 输出文件夹（保存生成的GeoJSON文件）

# 确保输出目录存在
os.makedirs(output_dir, exist_ok=True)

# 获取文件夹中的所有TIF文件
tif_files = [f for f in os.listdir(input_dir) if f.endswith('_A.tif')]

# 遍历每个TIF文件
for tif_file in tif_files:
    tif_path = os.path.join(input_dir, tif_file)  # 获取TIF文件的完整路径

    # 读取 TIF 文件，获取原始边界并转换坐标系
    with rasterio.open(tif_path) as src:
        src_crs = src.crs  # 获取 TIF 的投影坐标系
        bounds = src.bounds  # 获取原始边界 (左, 下, 右, 上)

        # 将边界转换为 EPSG:4326（WGS 84 经纬度）
        min_lon, min_lat, max_lon, max_lat = transform_bounds(
            src_crs, "EPSG:4326", bounds.left, bounds.bottom, bounds.right, bounds.top
        )

        # 计算边界中心点
        center_lon = (min_lon + max_lon) / 2
        center_lat = (min_lat + max_lat) / 2

        # 扩大边界 1.1 倍
        scale_factor = 1.1  # 扩大 10%
        new_min_lon = center_lon - (center_lon - min_lon) * scale_factor
        new_max_lon = center_lon + (max_lon - center_lon) * scale_factor
        new_min_lat = center_lat - (center_lat - min_lat) * scale_factor
        new_max_lat = center_lat + (max_lat - center_lat) * scale_factor

        # 创建扩展后的边界矩形
        bbox_geom = box(new_min_lon, new_min_lat, new_max_lon, new_max_lat)

    # 生成 GeoJSON 格式的边界数据
    geojson = {
        "type": "FeatureCollection",
        "features": [
            {"type": "Feature", "geometry": mapping(bbox_geom), "properties": {"crs": "EPSG:4326", "scale_factor": scale_factor}}
        ]
    }

    # 生成GeoJSON文件路径（保持文件名不变，修改后缀为 .geojson）
    geojson_file_name = tif_file.replace("_A.tif", ".geojson")
    geojson_path = os.path.join(output_dir, geojson_file_name)

    # 保存为 GeoJSON 文件
    with open(geojson_path, "w", encoding="utf-8") as f:
        json.dump(geojson, f, ensure_ascii=False, indent=4)

    print(f"GeoJSON 文件已保存: {geojson_path}")
