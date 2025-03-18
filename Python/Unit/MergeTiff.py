import os
import rasterio
from rasterio.merge import merge

# 设置输入文件夹（存放4个子区域的TIF）
input_folder = r"D:\0Program\Python\PatchMaker\Datasets\intput\split"
output_tif = r"D:\0Program\Python\PatchMaker\Datasets\intput\C07.tif"

# 获取所有TIF文件路径
tif_files = [os.path.join(input_folder, f) for f in os.listdir(input_folder) if f.endswith(".tiff")]

# 确保有TIF文件
if not tif_files:
    raise ValueError("未找到任何TIF文件，请检查路径！")

# 读取并合并TIF
src_files_to_mosaic = [rasterio.open(tif) for tif in tif_files]
mosaic, out_transform = merge(src_files_to_mosaic)

# 复制元数据（使用第一个TIF文件的元数据）
out_meta = src_files_to_mosaic[0].meta.copy()
out_meta.update({
    "driver": "GTiff",
    "height": mosaic.shape[1],
    "width": mosaic.shape[2],
    "transform": out_transform
})

# 保存合并后的TIF
with rasterio.open(output_tif, "w", **out_meta) as dest:
    dest.write(mosaic)

# 关闭所有打开的文件
for src in src_files_to_mosaic:
    src.close()

print(f"合并完成！合并后的TIF已保存至: {output_tif}")