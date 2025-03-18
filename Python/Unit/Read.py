import rasterio
import json
from shapely.geometry import box, mapping
from rasterio.warp import transform_bounds

# 指定 TIF 文件路径（请替换为你的 TIF 文件路径）
tif_path = r"D:\0Program\Python\PatchMaker\Datasets\intput\A10.tif"

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

# 指定输出的 GeoJSON 文件路径
geojson_path = r"D:\0Program\Python\PatchMaker\Datasets\geo\output_bbox_expanded.geojson"

# 保存为 GeoJSON 文件
with open(geojson_path, "w", encoding="utf-8") as f:
    json.dump(geojson, f, ensure_ascii=False, indent=4)

print(f"GeoJSON 文件已保存: {geojson_path}")
