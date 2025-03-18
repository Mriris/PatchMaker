PRO Generate_DEM
  ; 初始化 ENVI 和 SARscape 批处理模式
  PRINT, '启动 ENVI 并初始化 SARscape 批处理模式...'
  ENVI, /RESTORE_BASE_SAVE_FILES
  ENVI_BATCH_INIT

  ; 创建 SARscapeBatch 对象，用于 GMTED DEM 提取
  PRINT, '为 GMTED2010 DEM 提取创建 SARscape 批处理对象...'
  oSB = obj_new('SARscapeBatch', Module='ToolsDEMExtractionGmted')

  ; 检查对象是否创建成功
  IF (~OBJ_VALID(oSB)) THEN BEGIN
    PRINT, '错误: SARscape 批处理对象初始化失败。'
    SARscape_Batch_Exit
    RETURN
  ENDIF

  ; 列出模块的所有参数
  PRINT, '列出模块参数...'
  oSB.ListParams

  ; 设置输入和输出路径
  input_folder = 'D:\0Program\Datasets\241120\outputs\filtered_outputs\'  ; 输入文件夹
  output_folder = 'D:\0Program\Datasets\241120\outputs\dem_outputs\'      ; DEM 输出文件夹

  ; 搜索 `_fil` 文件作为输入
  PRINT, '正在搜索 DEM 提取的输入文件 (_fil)...'
  file_list = FILE_SEARCH(input_folder, '*_fil')  ; 搜索所有 `_fil` 文件
  IF N_ELEMENTS(file_list) EQ 0 THEN BEGIN
    PRINT, '未找到输入文件 (_fil): ', input_folder
    RETURN
  ENDIF

  ; 遍历文件列表并逐一处理
  FOR i = 0, N_ELEMENTS(file_list) - 1 DO BEGIN
    input_file = file_list[i]
    output_file = output_folder + FILE_BASENAME(input_file) + '_dem'  ; DEM 输出文件名

    ; 设置 DEM 输入和输出参数
    PRINT, '正在处理文件: ', input_file
    ok = oSB.SetParam('reference_sr_image_val', [input_file])  ; 设置输入文件
    ok = oSB.SetParam('output_file_dem_val', [output_file])    ; 设置输出文件路径
    ok = oSB.SetParam('grid_size', 450.0)                     ; 网格大小为 450 米

    ; 设置投影参数
    PRINT, '设置投影参数...'
    ok = oSB.SetParam('ocs_state', 'UTM-GLOBAL')         ; 投影方式
    ok = oSB.SetParam('ocs_hemisphere', 'NORTH')         ; 北半球
    ok = oSB.SetParam('ocs_projection', 'UTM')           ; UTM 投影
    ok = oSB.SetParam('ocs_zone', '49')                  ; UTM Zone 49
    ok = oSB.SetParam('ocs_ellipsoid', 'WGS84')          ; 椭球为 WGS84
    ok = oSB.SetParam('ocs_reference_height', 0.0)       ; 基准高程

    ; 验证设置的参数
    PRINT, '验证参数设置...'
    oSB.ListParams
    ok = oSB.VerifyParams()
    IF NOT ok THEN BEGIN
      PRINT, '参数验证失败，请检查输入设置: ', input_file
      CONTINUE
    ENDIF

    ; 执行 DEM 提取任务
    PRINT, '执行 DEM 提取任务: ', input_file
    ok = oSB.ExecuteProgress()
    IF NOT ok THEN BEGIN
      PRINT, 'DEM 提取过程中发生错误: ', input_file
      CONTINUE
    ENDIF

    PRINT, 'DEM 提取完成，文件保存在: ', output_file
  ENDFOR

  ; 释放对象并退出批处理模式
  obj_destroy, oSB
  SARscape_Batch_Exit
  PRINT, '所有 DEM 提取任务已完成。'
END
