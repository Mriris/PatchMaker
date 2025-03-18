PRO GF3_Multilooking_Process
  ; 初始化 ENVI 和 SARscape 批处理模式
  PRINT, '启动 ENVI 并初始化 SARscape 批处理模式...'
  ENVI, /RESTORE_BASE_SAVE_FILES
  ENVI_BATCH_INIT

  ; 设置临时目录（确保此目录存在）
  temporary_directory = 'D:\0Program\Datasets\241120\temp_sarscape'
  SARscape_Batch_Init, Temp_Directory=temporary_directory

  ; 加载 SARscape 扩展
  PRINT, '加载 SARscape 扩展...'
  a = sarmap_core_essentials(EXT_ONLY_SARMAP_CORE=1)

  ; 创建 SARscapeBatch 对象，设置模块为 BaseMultilooking
  PRINT, '为 BaseMultilooking 创建 SARscape 批处理对象...'
  oSB = obj_new('SARscapeBatch', Module='BaseMultilooking')

  ; 检查对象是否创建成功
  IF (~OBJ_VALID(oSB)) THEN BEGIN
    PRINT, '错误: SARscape 批处理对象初始化失败。'
    SARscape_Batch_Exit
    RETURN
  ENDIF

  ; 输入和输出文件夹
  input_folder = 'D:\0Program\Datasets\241120\outputs\import\' ; 多视处理的输入数据文件路径
  output_folder = 'D:\0Program\Datasets\241120\outputs\multilooking_outputs\' ; 多视处理的输出路径

  ; 搜索输入文件（假设为导入后的文件名以 _slc 结尾）
  PRINT, '正在搜索多视处理的输入文件 (_slc)...'
  file_list = FILE_SEARCH(input_folder, '*_slc')  ; 改为处理 _slc 结尾的文件
  IF N_ELEMENTS(file_list) EQ 0 THEN BEGIN
    PRINT, '在输入文件夹中未找到 _slc 结尾的文件: ', input_folder
    RETURN
  ENDIF

  ; 遍历文件列表并添加到批处理任务中
  FOR i = 0, N_ELEMENTS(file_list) - 1 DO BEGIN
    input_file = file_list[i]
    output_file = output_folder + FILE_BASENAME(input_file) + '_multilooked_pwr'  ; 输出为 _pwr 格式

    ; 解析 SML 文件
    sml_file = input_file + '.sml'
    PRINT, '解析 SML 文件: ', sml_file
    pixel_spacing_az = -1
    pixel_spacing_rg = -1
    incidence_angle = -1

    IF FILE_TEST(sml_file) THEN BEGIN
      OPENR, unit, sml_file, /GET_LUN
      line = ''
      WHILE NOT EOF(unit) DO BEGIN
        READF, unit, line

        ; 提取 PixelSpacingAz 和 PixelSpacingRg
        IF STRPOS(line, '<PixelSpacingAz>') NE -1 THEN BEGIN
          var = line.Split('>')
          middle_part = var[1]
          pixel_spacing_azA = FLOAT(middle_part.Split('<'))
          pixel_spacing_az=pixel_spacing_azA[0]
          PRINT, 'Extracted PixelSpacingAz: ', pixel_spacing_az
        ENDIF

        IF STRPOS(line, '<PixelSpacingRg>') NE -1 THEN BEGIN
          var = line.Split('>')
          middle_part = var[1]
          pixel_spacing_rgA = FLOAT(middle_part.Split('<'))
          pixel_spacing_rg=pixel_spacing_rgA[0]
          PRINT, 'Extracted PixelSpacingRg: ', pixel_spacing_rg
        ENDIF

        ; 提取 IncidenceAngle
        IF STRPOS(line, '<IncidenceAngle>') NE -1 THEN BEGIN
          var = line.Split('>')
          middle_part = var[1]
          incidence_angleA = FLOAT(middle_part.Split('<'))
          incidence_angle=incidence_angleA[0]
          PRINT, 'Extracted IncidenceAngle: ', incidence_angle
        ENDIF
      ENDWHILE
      FREE_LUN, unit
    ENDIF

    ; 检查是否成功提取参数
    IF (pixel_spacing_az LT 0 OR pixel_spacing_rg LT 0 OR incidence_angle LT 0) THEN BEGIN
      PRINT, '从 SML 文件提取参数失败: ', sml_file
      CONTINUE
    ENDIF

    ; 计算多视因子
    ground_resolution = pixel_spacing_rg / SIN(!PI * incidence_angle / 180.0)
    range_multilook = CEIL(ground_resolution / pixel_spacing_rg)
    azimuth_multilook = CEIL(ground_resolution / pixel_spacing_az)
    PRINT, '自动计算的多视因子 - Range Looks: ', range_multilook, ', Azimuth Looks: ', azimuth_multilook

    ; 设置输入和输出参数
    PRINT, '正在处理文件: ', input_file
    ok = oSB.SetParam('input_file_list', [input_file])
    ok = oSB.SetParam('output_file_list', [output_file])

    ; 设置多视处理参数
    PRINT, '设置多视处理参数...'
    ok = oSB.SetParam('range_multilook', STRTRIM(range_multilook, 2))
    ok = oSB.SetParam('azimuth_multilook', STRTRIM(azimuth_multilook, 2))

    ; 设置多视方法为时域
    PRINT, '设置多视处理方法为时域...'
    ok = oSB.SetParam('multilook_method', 'time_domain')

    ; 验证参数是否设置正确
    PRINT, '验证文件的参数: ', input_file
    ok = oSB.VerifyParams()
    IF NOT ok THEN BEGIN
      PRINT, '文件参数验证失败: ', input_file
      CONTINUE
    ENDIF

    ; 执行任务
    PRINT, '执行文件的任务: ', input_file
    ok = oSB.Execute()
    IF NOT ok THEN BEGIN
      PRINT, '文件执行过程中发生错误: ', input_file
      CONTINUE
    ENDIF

    PRINT, '文件处理完成: ', input_file
  ENDFOR

  ; 释放对象并退出批处理模式
  obj_destroy, oSB
  SARscape_Batch_Exit
  PRINT, '多视处理批处理完成。'
END
