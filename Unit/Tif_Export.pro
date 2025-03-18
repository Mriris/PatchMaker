PRO Tif_Export
; 启动ENVI应用
e = ENVI()

; 获取A文件夹中的所有TIFF文件
A_folder = 'C:\0Program\Datasets\241120\Compare\Datas\Test\B\'  ; 请根据实际情况修改A文件夹路径
files = FILE_SEARCH(A_folder + '*.tif')

; 如果没有找到TIFF文件，则结束
IF (N_ELEMENTS(files) EQ 0) THEN BEGIN
  PRINT, '没有找到任何TIFF文件！'
  RETURN
ENDIF

; 获取视图，确保视图已创建
view = e.CreateView()  ; 使用 CreateView 代替 GetView

; 遍历所有TIFF文件
FOR i = 0, N_ELEMENTS(files) - 1 DO BEGIN
  file = files[i]

  ; 打开当前TIFF文件
  raster = e.OpenRaster(file)

  ; 创建一个新的栅格图层
  rasterLayer = view.createLayer(raster)

  ; 创建导出的文件名，将B文件夹路径加到文件名之前
  newFile = 'C:\0Program\Datasets\241120\Compare\Datas\Test\tif\' + FILE_BASENAME(file)

  ; 导出TIFF文件
  rasterLayer.Export, newFile, 'TIFF'

  ; 输出完成信息
  PRINT, '已将文件导出至: ', newFile
ENDFOR

PRINT, '所有TIFF文件已导出完成！'
END
