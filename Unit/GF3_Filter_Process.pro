PRO GF3_Filter_Process
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

  ; 创建 SARscapeBatch 对象，设置模块为 DespeckleConventionalSingle
  PRINT, '为 DespeckleConventionalSingle 创建 SARscape 批处理对象...'
  oSB = obj_new('SARscapeBatch', Module='DespeckleConventionalSingle')

  ; 检查对象是否创建成功
  IF (~OBJ_VALID(oSB)) THEN BEGIN
    PRINT, '错误: SARscape 批处理对象初始化失败。'
    SARscape_Batch_Exit
    RETURN
  ENDIF
  
  ; 列出模块的所有参数
  PRINT, '列出模块参数...'
  oSB.ListParams

  ; 输入和输出文件夹
  input_folder = 'D:\0Program\Datasets\241120\outputs\multilooking_outputs\' ; 输入数据文件路径
  output_folder = 'D:\0Program\Datasets\241120\outputs\filtered_outputs\' ; 输出数据文件路径

  ; 搜索输入文件（假设为导入后的文件名以 _pwr 结尾）
  PRINT, '正在搜索滤波处理的输入文件 (_pwr)...'
  file_list = FILE_SEARCH(input_folder, '*_pwr')  ; 改为处理 _pwr 结尾的文件
  IF N_ELEMENTS(file_list) EQ 0 THEN BEGIN
    PRINT, '在输入文件夹中未找到 _pwr 结尾的文件: ', input_folder
    RETURN
  ENDIF

  ; 遍历文件列表并添加到批处理任务中
  FOR i = 0, N_ELEMENTS(file_list) - 1 DO BEGIN
    input_file = file_list[i]
    output_file = output_folder + FILE_BASENAME(input_file) + '_fil' 

    ; 设置输入和输出参数
    PRINT, '正在处理文件: ', input_file
    ok = oSB.SetParam('input_file_list', [input_file])
    ok = oSB.SetParam('output_file_list', [output_file])

    ; 设置滤波参数
    PRINT, '设置滤波参数...'
    ok = oSB.SetParam('filt_type', 'Refined Lee') ; 滤波器类型：Refined Lee
    ok = oSB.SetParam('rows_window_number', 5) ; 窗口大小（行）
    ok = oSB.SetParam('cols_window_number', 5) ; 窗口大小（列）

    ; 验证参数是否设置正确
    PRINT, '验证文件的参数: ', input_file
    ok = oSB.VerifyParams()
    IF NOT ok THEN BEGIN
      PRINT, '文件参数验证失败: ', input_file
      CONTINUE
    ENDIF

    ; 执行任务
    PRINT, '执行文件的任务: ', input_file
    ok = oSB.ExecuteProgress()
    IF NOT ok THEN BEGIN
      PRINT, '文件执行过程中发生错误: ', input_file
      CONTINUE
    ENDIF

    PRINT, '文件处理完成: ', input_file
  ENDFOR

  ; 释放对象并退出批处理模式
  obj_destroy, oSB
  SARscape_Batch_Exit
  PRINT, '单通道滤波批处理完成。'
END
