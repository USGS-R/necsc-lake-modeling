cleanup_stream_temp_data = function(temp){
  temp = subset(temp, CharacteristicName == 'Temperature, water')
  temp = subset(temp, ResultMeasure.MeasureUnitCode %in% c('deg C', 'deg F'))
  temp$ResultMeasureValue[temp$ResultMeasure.MeasureUnitCode == 'deg F'] = (temp$ResultMeasureValue[temp$ResultMeasure.MeasureUnitCode == 'deg F'] - 32)/1.8
  temp$ResultMeasure.MeasureUnitCode = 'deg C'
  temp = subset(temp, ResultMeasureValue < 40)
  return(temp)
}