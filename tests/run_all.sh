#!/bin/sh

SOURCE=../../media/Chimera50_FTR_C_EN_XG-NR_20_4K_20150622_OV/Chimera50_FTR_C_EN_XG-NR_20_4K_20150622_OV.mxf

./test1080i23976.sh $SOURCE
./test1080i2997.sh $SOURCE
./test1080p23976.sh $SOURCE
./test1080p24.sh $SOURCE
./test1080p25.sh $SOURCE
./test1080p2997.sh $SOURCE
./test1080p30.sh $SOURCE
./test480i2997_16_9.sh $SOURCE
./test480i2997_4_3.sh $SOURCE
./test480p23976_16_9.sh $SOURCE
./test480p23976_4_3.sh $SOURCE
./test480p24_16_9.sh $SOURCE
./test480p24_4_3.sh $SOURCE
./test480p2997_16_9.sh $SOURCE
./test480p2997_4_3.sh $SOURCE
./test576i25_16_9.sh $SOURCE
./test576i25_4_3.sh $SOURCE
./test576p23976_16_9.sh $SOURCE
./test576p23976_4_3.sh $SOURCE
./test576p24_16_9.sh $SOURCE
./test576p24_4_3.sh $SOURCE
./test576p25_16_9.sh $SOURCE
./test576p25_4_3.sh $SOURCE
./test720i23976.sh $SOURCE
./test720i2997.sh $SOURCE
./test720p23976.sh $SOURCE
./test720p24.sh $SOURCE
./test720p25.sh $SOURCE
./test720p2997.sh $SOURCE
./test720p30.sh $SOURCE
