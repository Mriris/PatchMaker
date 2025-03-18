import os
import rasterio
from rasterio.mask import mask
from rasterio.features import shapes
import numpy as np
from shapely.geometry import shape, mapping
from shapely.ops import unary_union
import geopandas as gpd

# 设置基础输入和输出目录
base_input_dir = r"D:\0Program\Python\PatchMaker\Datasets\intput"
base_output_dir = r"D:\0Program\Python\PatchMaker\Datasets\intput"

# 确保输出目录存在
os.makedirs(base_output_dir, exist_ok=True)

# 定义图像的路径
optical_image_path = os.path.join(base_input_dir, "A10.tif")
sar_image_path = os.path.join(base_input_dir, "C04.tif")

# 定义影像裁剪后的输出文件路径
cropped_sar_output_path = os.path.join(base_output_dir, "C05.tif")

# 打开两幅图像并获取重叠区域
with rasterio.open(optical_image_path) as src1, rasterio.open(sar_image_path) as src2:
    # 获取有效像素掩膜（>0表示有效）
    mask1 = src1.dataset_mask() > 0  # 光学影像的有效区域掩膜
    mask2 = src2.dataset_mask() > 0  # SAR影像的有效区域掩膜

    # 将掩膜转换为几何对象
    shapes1 = [shape(geom) for geom, val in shapes(mask1.astype(np.uint8), transform=src1.transform) if val > 0]
    shapes2 = [shape(geom) for geom, val in shapes(mask2.astype(np.uint8), transform=src2.transform) if val > 0]

    # 计算各自的有效区域
    union1 = unary_union(shapes1)  # 光学影像有效区域
    union2 = unary_union(shapes2)  # SAR影像有效区域

    # 计算两幅影像的重叠区域
    overlap = union1.intersection(union2)

    # 如果没有重叠区域，则报错
    if overlap.is_empty:
        raise ValueError("两幅图像没有实际内容的重叠区域！")

    # 转换为GeoDataFrame（便于检查）
    overlap_gdf = gpd.GeoDataFrame({"geometry": [overlap]}, crs=src1.crs)

    # 仅裁剪图像
    cropped_image2, cropped_transform2 = mask(src2, [mapping(overlap)], crop=True)

    # 更新影像的元数据
    meta2 = src2.meta.copy()
    meta2.update({
        "driver": "GTiff",
        "height": cropped_image2.shape[1],
        "width": cropped_image2.shape[2],
        "transform": cropped_transform2
    })

    # 保存裁剪后的图像
    with rasterio.open(cropped_sar_output_path, "w", **meta2) as dest2:
        dest2.write(cropped_image2)

print("裁剪完成！仅裁剪2号影像，结果已保存至：")
print(f"SAR图像: {cropped_sar_output_path}")
