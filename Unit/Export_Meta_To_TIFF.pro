PRO Export_Meta_To_TIFF
  ; 初始化 ENVI 环境
  PRINT, '启动 ENVI 并加载环境...'
  e = ENVI(/HEADLESS)  ; 启动 ENVI
  IF NOT OBJ_VALID(e) THEN BEGIN
    PRINT, 'ENVI 初始化失败。'
    RETURN
  ENDIF

  ; 定义输入和输出路径
  meta_file = 'D:\0Program\Datasets\241120\outputs\geo_outputs\gaofer3_20211115_224934849_D_geo_db_meta'
  output_tiff_file = 'D:\0Program\Datasets\241120\outputs\geo_outputs\gaofer3_20211115_224934849_D_geo.tif'

  ; 检查输入文件是否存在
  IF NOT FILE_TEST(meta_file) THEN BEGIN
    PRINT, '输入文件不存在: ', meta_file
    RETURN
  ENDIF

  ; 加载输入 raster
  PRINT, '加载输入文件: ', meta_file
  Raster = e.OpenRaster(meta_file)
  IF NOT OBJ_VALID(Raster) THEN BEGIN
    PRINT, '加载输入文件失败: ', meta_file
    RETURN
  ENDIF

  ; 获取任务
  PRINT, '获取 ExportRasterToTIFF 任务...'
  Task = ENVITask('ExportRasterToTIFF')
  IF NOT OBJ_VALID(Task) THEN BEGIN
    PRINT, '获取任务失败。'
    RETURN
  ENDIF

  ; 设置任务参数
  PRINT, '设置任务参数...'
  Task.INPUT_RASTER = Raster  ; 设置输入 raster
  Task.OUTPUT_RASTER_URI = output_tiff_file  ; 设置输出路径
  Task.DATA_IGNORE_VALUE = 0  ; 设置无效值（可根据需求调整）

  ; 执行任务
  PRINT, '执行任务...'
  Task.Execute

  ; 验证输出
  IF FILE_TEST(output_tiff_file) THEN BEGIN
    PRINT, '导出完成，文件保存至: ', output_tiff_file
  ENDIF ELSE BEGIN
    PRINT, '导出失败，请检查配置。'
  ENDELSE

  ; 释放资源
  OBJ_DESTROY, Raster
  PRINT, '任务完成。'
END
