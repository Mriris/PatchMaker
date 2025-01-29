import os
import rasterio
from rasterio.mask import mask
from rasterio.features import geometry_mask
import numpy as np
from shapely.geometry import shape, mapping
from shapely.ops import unary_union
import geopandas as gpd

# 设置基础输入和输出目录
base_input_dir = r"D:\0Program\Python\labelme_cd_AI\examples\change_detective"
base_output_dir = r"D:\0Program\Python\labelme_cd_AI\examples\change_detective"

# 确保输出目录存在
os.makedirs(base_output_dir, exist_ok=True)

# 定义光学和SAR图像的路径
optical_image_path = os.path.join(base_input_dir, "A0.tif")
sar_image_path = os.path.join(base_input_dir, "B0.tif")

# 定义输出文件路径
cropped_optical_output_path = os.path.join(base_output_dir, "A9.tif")
cropped_sar_output_path = os.path.join(base_output_dir, "B9.tif")

# 打开两幅图像并获取掩膜
with rasterio.open(optical_image_path) as src1, rasterio.open(sar_image_path) as src2:
    # 获取掩膜（有效像素区域）
    mask1 = src1.dataset_mask() > 0  # 光学图像的有效区域掩膜
    mask2 = src2.dataset_mask() > 0  # SAR图像的有效区域掩膜

    # 将掩膜转换为几何对象
    shapes1 = [shape(geom) for geom, val in rasterio.features.shapes(mask1.astype(np.uint8), transform=src1.transform) if val > 0]
    shapes2 = [shape(geom) for geom, val in rasterio.features.shapes(mask2.astype(np.uint8), transform=src2.transform) if val > 0]

    # 合并掩膜区域为一个多边形
    union1 = unary_union(shapes1)
    union2 = unary_union(shapes2)

    # 计算重叠区域（直接使用几何对象的 intersection 方法）
    overlap = union1.intersection(union2)
    # print("重叠区域:", overlap)

    # 如果没有重叠，提示用户
    if overlap.is_empty:
        raise ValueError("两幅图像没有实际内容的重叠区域！")

    # 转换为GeoDataFrame
    overlap_gdf = gpd.GeoDataFrame({"geometry": [overlap]}, crs=src1.crs)

    # 裁剪光学图像
    cropped_image1, cropped_transform1 = mask(src1, [mapping(overlap)], crop=True)
    # 裁剪SAR图像
    cropped_image2, cropped_transform2 = mask(src2, [mapping(overlap)], crop=True)

    # 更新元数据并保存裁剪结果
    meta1 = src1.meta.copy()
    meta1.update({
        "driver": "GTiff",
        "height": cropped_image1.shape[1],
        "width": cropped_image1.shape[2],
        "transform": cropped_transform1
    })

    meta2 = src2.meta.copy()
    meta2.update({
        "driver": "GTiff",
        "height": cropped_image2.shape[1],
        "width": cropped_image2.shape[2],
        "transform": cropped_transform2
    })

    with rasterio.open(cropped_optical_output_path, "w", **meta1) as dest1:
        dest1.write(cropped_image1)
    with rasterio.open(cropped_sar_output_path, "w", **meta2) as dest2:
        dest2.write(cropped_image2)

print("裁剪完成！裁剪结果已保存至：")
print(f"光学图像: {cropped_optical_output_path}")
print(f"SAR图像: {cropped_sar_output_path}")
