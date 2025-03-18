PRO Generate_Meta_From_DB_With_Dimensions
  ; 设置输入文件夹和 meta 文件路径
  input_folder = 'D:\0Program\Datasets\241120\outputs\geo_outputs\'  ; 包含 _db 文件的目录
  output_meta_file = input_folder + 'gaofer3_20211115_224934849_D_geo_db_meta'

  ; 搜索所有 _db 文件
  PRINT, '正在搜索 _db 文件...'
  db_files = FILE_SEARCH(input_folder, '*_db')  ; 搜索所有以 _db 结尾的文件
  IF N_ELEMENTS(db_files) EQ 0 THEN BEGIN
    PRINT, '未找到任何 _db 文件: ', input_folder
    RETURN
  ENDIF

  ; 倒序文件列表
  db_files = REVERSE(db_files)

  ; 打开文件写入
  PRINT, '正在生成 meta 文件: ', output_meta_file
  OPENW, unit, output_meta_file, /GET_LUN
  PRINTF, unit, 'ENVI META FILE'

  ; 初始化 ENVI 环境
  PRINT, '启动 ENVI 环境以读取文件信息...'
  e = ENVI(/HEADLESS)  ; 启动 ENVI
  IF NOT OBJ_VALID(e) THEN BEGIN
    PRINT, 'ENVI 初始化失败。'
    FREE_LUN, unit
    RETURN
  ENDIF

  ; 遍历所有 _db 文件
  FOR i = 0, N_ELEMENTS(db_files) - 1 DO BEGIN
    db_file = db_files[i]
    PRINT, '处理文件: ', db_file

    ; 打开 _db 文件
    raster = e.OpenRaster(db_file)
    IF NOT OBJ_VALID(raster) THEN BEGIN
      PRINT, '加载文件失败: ', db_file
      CONTINUE
    ENDIF

    ; 获取波段数、列数和行数
    bands = raster.NBANDS
    rows = raster.NCOLUMNS
    cols = raster.NROWS

    ; 写入 meta 文件内容（格式化）
    short_filename = FILE_BASENAME(db_file)  ; 提取短文件名
    PRINTF, unit, 'File : ', short_filename
    PRINTF, unit, 'Bands: ', STRING(bands, FORMAT='(I1)')  ; 确保波段数格式为整齐的单行
    PRINTF, unit, 'Dims : 1-', STRING(rows, FORMAT='(I0)'), ',1-', STRING(cols, FORMAT='(I0)')
    PRINTF, unit, ''  ; 空行分隔每个文件的信息

    ; 释放 raster 对象
    OBJ_DESTROY, raster
  ENDFOR

  ; 关闭文件和 ENVI 环境
  FREE_LUN, unit
  PRINT, 'Meta 文件生成完成: ', output_meta_file
END
