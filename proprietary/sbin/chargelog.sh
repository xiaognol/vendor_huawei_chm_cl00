#!/system/bin/sh
#usage: chargelog.sh  <interval(sec)> <maxline>

PS_PATH="/sys/class/power_supply/"

#if some node infomation is redundant,the node should be commented
#in this array. 

NODE_NAME=( \
#---------------------------------------
#battery power supply
#---------------------------------------
"battery/capacity" \
#"battery/charge_full_design" \
"battery/charge_type" \
"battery/charging_enabled" \
#"battery/current_max" \
"battery/current_now" \
"battery/health" \
"battery/present" \
"battery/status" \
#"battery/system_temp_level" \
#"battery/technology" \
#"battery/online" \
"battery/temp" \
#"battery/type" \
#"battery/voltage_max_design" \
#"battery/voltage_min_design" \
"battery/voltage_now" \
"battery/hot_current_limit" \
"battery/input_current_max" \
#"battery/factory_diag" \
#"battery/online" \
#---------------------------------------
#bms power supply
#---------------------------------------
#"bms/capacity" \
#"bms/charge_full_design" \
#"bms/current_max" \
#"bms/current_now" \
#"bms/present" \
#"bms/type" \
"bms/battery_type" \
"bms/voltage_ocv" \
#---------------------------------------
#usb power supply
#---------------------------------------
"usb/current_max" \
"usb/voltage_max" \
"usb/voltage_now" \
"usb/online" \
"usb/present" \
"usb/scope" \
"usb/type" \
"battery/charge_log" \
)

NODE_NAME_MAXIM=( \
#---------------------------------------
#max77819-charger power supply
#---------------------------------------
"max77819-charger/capacity" \
"max77819-charger/voltage_now" \
"max77819-charger/current_now" \
"max77819-charger/status" \
"max77819-charger/health" \
"max77819-charger/temp" \
"max77819-charger/charge_type" \
"max77819-charger/resume_charging" \
"max77819-charger/constant_charge_current_max" \
"max77819-charger/constant_charge_current" \
"max77819-charger/present" \
"max77819-charger/charge_log" \
#---------------------------------------
#battery power supply
#---------------------------------------
"battery/charging_enabled" \
"battery/factory_diag" \
"battery/hot_current_limit" \
#---------------------------------------
#usb power supply
#---------------------------------------
"usb/current_max" \
"usb/online" \
"usb/present" \
"usb/scope" \
"usb/type" \
)

charge_mode=1

#check if system partition has been mounted,
#if no, shell script can not execute. 
#this code block test this case.

id
if [ $? -ne 0 ];then
    exit
fi

cat /proc/cmdline | grep charger
if [ $? -eq 0 ];then
    charge_mode=0
fi

#check log path
cat /data/property/persist.sys.chargelog | grep data
if [ $? -ne 0 ];then
    stop chargelog
    read
fi

test -d "/data/log/chargelog/"
if [ $? -ne 0 ];then
    mkdir -p "/data/log/chargelog/"
    chmod 755 /data/log/chargelog
fi
log_path="/data/log/chargelog/chargelog.csv"

echo "---> log path is $log_path"

file_size=0

#---------------------------------------------------------------------------------------------------------------------------------
# get log type by product board id
#/* <DTS2015082203230 yinfenghang 20150822 begin */

log_type_qcom=0
log_type_ti=1
log_type_maxim=2
log_type_ti_low=3
log_type_ti_only=4
log_type_ti_bms=5
BOARD_ID_TI=( \
"MSM8939_ATH" \
"MSM8939_RIO" \
"MSM8939_KIW" \
)

BOARD_ID_MAXIM=( \
"MSM8939_G760S-CL00_VA" \
"MSM8939_C199s_VA" \
)

BOARD_ID_TI_LOW=( \
"MSM8939_ALE" \
)
BOARD_ID_TI_ONLY=( \
"MSM8939_CHM-CL00_VB" \
"MSM8939_C8818" \
)
BOARD_ID_TI_BMS=( \
"MSM8939_KIW_TL00H_VT" \
)

log_type=$log_type_qcom

for board_id in ${BOARD_ID_TI[@]}
do
    cat /proc/app_info | grep "$board_id"
    if [ $? -eq 0 ];then
        log_type=$log_type_ti
        break
    fi
done

for board_id in ${BOARD_ID_MAXIM[@]}
do
    cat /proc/app_info | grep "$board_id"
    if [ $? -eq 0 ];then
        log_type=$log_type_maxim
        break
    fi
done
for board_id in ${BOARD_ID_TI_LOW[@]}
do
    cat /proc/app_info | grep "$board_id"
    if [ $? -eq 0 ];then
        log_type=$log_type_ti_low
        break
    fi
done
for board_id in ${BOARD_ID_TI_ONLY[@]}
do
    cat /proc/app_info | grep "$board_id"
    if [ $? -eq 0 ];then
        log_type=$log_type_ti_only
        break
    fi
done
for board_id in ${BOARD_ID_TI_BMS[@]}
do
    cat /proc/app_info | grep "$board_id"
    if [ $? -eq 0 ];then
        log_type=$log_type_ti_bms
        break
    fi
done
#/* DTS2015082203230 yinfenghang 20150822 end> */
#---------------------------------------------------------------------------------------------------------------------------------

if [ $log_type -eq $log_type_maxim ];then
#Maxim log begin
    cat $log_path | grep time
    if [ $? -ne 0 ];then
        echo -n "date " >> $log_path
        echo -n "time " >> $log_path
        for path in ${NODE_NAME_MAXIM[@]}
        do
            echo -n "$path" >> $log_path
            echo -n ' ' >> $log_path
        done
        echo -n "MODE" >> $log_path
        echo >> $log_path
        chmod 755 $log_path
    fi

    while :
    do
        echo -n `date +%0m-%0e` >> $log_path
        echo -n ' ' >> $log_path
        echo -n `date +%H:%M:%S` >> $log_path
        echo -n ' ' >> $log_path

        for path in ${NODE_NAME_MAXIM[@]}
        do
            echo -n `cat "$PS_PATH$path"` >> $log_path
            echo -n ' ' >> $log_path
        done

        if [ charge_mode -eq 1 ];then
            echo -n "ON" >> $log_path
        else
            echo -n "OFF" >> $log_path
        fi

        echo >> $log_path

        #get log file size
        TEMP=`ls -s $log_path`
        arr=(${TEMP})
        file_size=${arr[0]}

        if [ $file_size -ge $2 ];then
            mv $log_path $log_path".old.csv"
            file_size=0
        fi
        sync
        sleep $1
    done

elif [ $log_type -eq $log_type_ti ];then
#---------------------------------------------------------------------------------------------------------------------------------
#Ti log begin
    echo -n "Date Time,Voltage,Current,brightness,SOC,TEMP,Reg[0],Reg[1],Reg[2],Reg[3],Reg[4],Reg[5],Reg[6],Reg[7],Reg[8],Reg[9],Reg[0A],ibus,usbonline,usbscope,usbtype,usbcurrentmax, batterypresent,hot_current_limit,health,status,charging_enabled,<cpu0_1_2_3><cpu4_5_6_7>,cpu0_cpuinfo_cur_freq,cpu0_scaling_max_freq,cpu4_cpuinfo_cur_freq,cpu4_scaling_max_freq,tsens_tz_sensor0,tsens_tz_sensor1,tsens_tz_sensor2[pop_mem],tsens_tz_sensor3[gpu],tsens_tz_sensor5[cpu0],tsens_tz_sensor6[cpu1],tsens_tz_sensor7[cpu2],tsens_tz_sensor8[cpu3],tsens_tz_sensor9[cpu4567],beside_cpu_tsens,beside_camera_tsens,Mode" >> $log_path
    echo >> $log_path
    chmod 755 /data/log/chargelog/chargelog.csv
    while true
    do
        echo -n `date +%0m-%0e` >> $log_path
        echo -n ' ' >> $log_path
        echo -n `date +%H:%M:%S` >> $log_path
        echo -n , >> $log_path

        echo -n `cat /sys/class/power_supply/battery/voltage_now` >> $log_path
        echo -n , >> $log_path
        echo -n `cat /sys/class/power_supply/battery/current_now` >> $log_path
        echo -n , >> $log_path
        echo -n `cat /sys/class/leds/lcd-backlight/brightness` >> $log_path
        echo -n , >> $log_path

        echo -n `cat /sys/class/power_supply/battery/capacity` >> $log_path
        echo -n , >> $log_path
        echo -n `cat /sys/class/power_supply/battery/temp` >> $log_path
        echo -n , >> $log_path
        echo -n `cat /sys/class/power_supply/battery/device/chargelog` >> $log_path
        #echo -n , >> $log_path

        echo -n `cat /sys/class/hw_power/charger/charge_data/ibus` >> $log_path
        echo -n , >> $log_path
        echo -n `cat /sys/class/power_supply/usb/online` >> $log_path
        echo -n , >> $log_path
        echo -n `cat /sys/class/power_supply/usb/scope` >> $log_path
        echo -n , >> $log_path
        echo -n `cat /sys/class/power_supply/usb/type` >> $log_path
        echo -n , >> $log_path
        echo -n `cat /sys/class/power_supply/usb/current_max` >> $log_path
        echo -n , >> $log_path
        echo -n `cat /sys/class/power_supply/battery/present` >> $log_path
        echo -n , >> $log_path
        echo -n `cat /sys/class/power_supply/battery/hot_current_limit` >> $log_path
        echo -n , >> $log_path

        echo -n `cat /sys/class/power_supply/battery/health` >> $log_path
        echo -n , >> $log_path
        echo -n `cat /sys/class/power_supply/battery/status` >> $log_path
        echo -n , >> $log_path
        echo -n `cat /sys/class/power_supply/battery/charging_enabled` >> $log_path
        echo -n , >> $log_path

        echo -n '   <' >> $log_path
        echo -n `cat /sys/devices/system/cpu/cpu0/online`     >> $log_path
        echo -n '_' >> $log_path
        echo -n `cat /sys/devices/system/cpu/cpu1/online`     >> $log_path
        echo -n '_' >> $log_path
        echo -n `cat /sys/devices/system/cpu/cpu2/online`     >> $log_path
        echo -n '_' >> $log_path
        echo -n `cat /sys/devices/system/cpu/cpu3/online`     >> $log_path

        echo -n '>   <' >> $log_path
        echo -n `cat /sys/devices/system/cpu/cpu4/online`     >> $log_path
        echo -n '_' >> $log_path
        echo -n `cat /sys/devices/system/cpu/cpu5/online`     >> $log_path
        echo -n '_' >> $log_path
        echo -n `cat /sys/devices/system/cpu/cpu6/online`     >> $log_path
        echo -n '_' >> $log_path
        echo -n `cat /sys/devices/system/cpu/cpu7/online`     >> $log_path
        echo -n '>' >> $log_path
        echo -n , >> $log_path

        for i in 0 1 2 3
        do
            online=`cat /sys/devices/system/cpu/cpu$i/online`
            if [[ $online = 1 ]] ;then
                echo -n `cat /sys/devices/system/cpu/cpu$i/cpufreq/cpuinfo_cur_freq` >> $log_path
                echo -n , >> $log_path
                echo -n `cat /sys/devices/system/cpu/cpu$i/cpufreq/scaling_max_freq` >> $log_path
                echo -n , >> $log_path
                break;
            fi

            if [[ $i = 3 ]] ;then
                echo -n ' '  >> $log_path
                echo -n , >> $log_path
                echo -n ' '  >> $log_path
                echo -n , >> $log_path
            fi
        done;


        for i in 4 5 6 7
        do
            online=`cat /sys/devices/system/cpu/cpu$i/online`
            if [[ $online = 1 ]] ;then
                echo -n `cat /sys/devices/system/cpu/cpu$i/cpufreq/cpuinfo_cur_freq` >> $log_path
                echo -n , >> $log_path
                echo -n `cat /sys/devices/system/cpu/cpu$i/cpufreq/scaling_max_freq` >> $log_path
                echo -n , >> $log_path
                break;
            fi
            if [[ $i = 7 ]] ;then
                echo -n ' '  >> $log_path
                echo -n , >> $log_path
                echo -n ' '  >> $log_path
                echo -n , >> $log_path
            fi
        done;

        echo -n `cat /sys/devices/virtual/thermal/thermal_zone0/temp` >> $log_path
        echo -n , >> $log_path
        echo -n `cat /sys/devices/virtual/thermal/thermal_zone1/temp` >> $log_path
        echo -n , >> $log_path
        echo -n `cat /sys/devices/virtual/thermal/thermal_zone2/temp` >> $log_path
        echo -n , >> $log_path
        echo -n `cat /sys/devices/virtual/thermal/thermal_zone3/temp` >> $log_path
        echo -n , >> $log_path
        echo -n `cat /sys/devices/virtual/thermal/thermal_zone4/temp` >> $log_path
        echo -n , >> $log_path
        echo -n `cat /sys/devices/virtual/thermal/thermal_zone5/temp` >> $log_path
        echo -n , >> $log_path
        echo -n `cat /sys/devices/virtual/thermal/thermal_zone6/temp` >> $log_path
        echo -n , >> $log_path
        echo -n `cat /sys/devices/virtual/thermal/thermal_zone7/temp` >> $log_path
        echo -n , >> $log_path
		echo -n `cat /sys/devices/virtual/thermal/thermal_zone8/temp` >> $log_path
        echo -n , >> $log_path
        echo -n `cat /sys/module/qpnp_adc_voltage/parameters/therm_cpu` >> $log_path
        echo -n , >> $log_path
        echo -n `cat /sys/module/qpnp_adc_voltage/parameters/therm_cam` >> $log_path
        echo -n , >> $log_path

        if [ charge_mode -eq 1 ];then
            echo -n "ON" >> $log_path
        else
            echo -n "OFF" >> $log_path
        fi

        echo >> $log_path

        #get log file size
        TEMP=`ls -s $log_path`
        arr=(${TEMP})
        file_size=${arr[0]}

        if [ $file_size -ge $2 ];then
            mv $log_path $log_path".old.csv"
            file_size=0
        fi
        sync
        sleep $1
    done
#Ti log end
#/* <DTS2015082203230 yinfenghang 20150822 begin */
elif [ $log_type -eq $log_type_ti_bms ];then
#---------------------------------------------------------------------------------------------------------------------------------
#Ti BMS log begin
    echo -n "Date Time,     Voltage Current SOC RM FCC II SI Temp FLAG Status Qmax ufrm frm uffcc ffcc ufsoc Voltage brightness SOC TEMP,Reg[0],Reg[1],Reg[2],Reg[3],Reg[4],Reg[5],Reg[6],Reg[7],Reg[8],Reg[9],Reg[0A],ibus,usbonline,usbscope,usbtype,usbcurrentmax,batterypresent,hot_current_limit,health,status,charging_enabled,<cpu0_1_2_3><cpu4_5_6_7>,cpu0_cpuinfo_cur_freq,cpu0_scaling_max_freq,cpu4_cpuinfo_cur_freq,cpu4_scaling_max_freq,tsens_tz_sensor0,tsens_tz_sensor1,tsens_tz_sensor2[pop_mem],tsens_tz_sensor3[gpu],tsens_tz_sensor5[cpu0],tsens_tz_sensor6[cpu1],tsens_tz_sensor7[cpu2],tsens_tz_sensor8[cpu3],tsens_tz_sensor9[cpu4567],beside_cpu_tsens,beside_camera_tsens,Mode" >> $log_path
    echo >> $log_path
    chmod 755 /data/log/chargelog/chargelog.csv
    while true
    do
        echo -n `date +%0m-%0e` >> $log_path
        echo -n ' ' >> $log_path
        echo -n `date +%H:%M:%S` >> $log_path
        echo -n , >> $log_path

		echo -n `cat /sys/bus/i2c/drivers/ti,bq27510/ti-bms-prop/gaugelog` >> $log_path
        echo -n ' ' >> $log_path
        echo -n `cat /sys/class/power_supply/battery/voltage_now` >> $log_path
        echo -n ' ' >> $log_path
        echo -n `cat /sys/class/leds/lcd-backlight/brightness` >> $log_path
        echo -n ' ' >> $log_path

        echo -n `cat /sys/class/power_supply/battery/capacity` >> $log_path
        echo -n ' ' >> $log_path
        echo -n `cat /sys/class/power_supply/battery/temp` >> $log_path
        echo -n , >> $log_path
        echo -n `cat /sys/class/power_supply/battery/device/chargelog` >> $log_path
        #echo -n , >> $log_path

        echo -n `cat /sys/class/hw_power/charger/charge_data/ibus` >> $log_path
        echo -n , >> $log_path
        echo -n `cat /sys/class/power_supply/usb/online` >> $log_path
        echo -n , >> $log_path
        echo -n `cat /sys/class/power_supply/usb/scope` >> $log_path
        echo -n , >> $log_path
        echo -n `cat /sys/class/power_supply/usb/type` >> $log_path
        echo -n , >> $log_path
        echo -n `cat /sys/class/power_supply/usb/current_max` >> $log_path
        echo -n , >> $log_path
        echo -n `cat /sys/class/power_supply/battery/present` >> $log_path
        echo -n , >> $log_path
        echo -n `cat /sys/class/power_supply/battery/hot_current_limit` >> $log_path
        echo -n , >> $log_path

        echo -n `cat /sys/class/power_supply/battery/health` >> $log_path
        echo -n , >> $log_path
        echo -n `cat /sys/class/power_supply/battery/status` >> $log_path
        echo -n , >> $log_path
        echo -n `cat /sys/class/power_supply/battery/charging_enabled` >> $log_path
        echo -n , >> $log_path

        echo -n '   <' >> $log_path
        echo -n `cat /sys/devices/system/cpu/cpu0/online`     >> $log_path
        echo -n '_' >> $log_path
        echo -n `cat /sys/devices/system/cpu/cpu1/online`     >> $log_path
        echo -n '_' >> $log_path
        echo -n `cat /sys/devices/system/cpu/cpu2/online`     >> $log_path
        echo -n '_' >> $log_path
        echo -n `cat /sys/devices/system/cpu/cpu3/online`     >> $log_path

        echo -n '>   <' >> $log_path
        echo -n `cat /sys/devices/system/cpu/cpu4/online`     >> $log_path
        echo -n '_' >> $log_path
        echo -n `cat /sys/devices/system/cpu/cpu5/online`     >> $log_path
        echo -n '_' >> $log_path
        echo -n `cat /sys/devices/system/cpu/cpu6/online`     >> $log_path
        echo -n '_' >> $log_path
        echo -n `cat /sys/devices/system/cpu/cpu7/online`     >> $log_path
        echo -n '>' >> $log_path
        echo -n , >> $log_path

        for i in 0 1 2 3
        do
            online=`cat /sys/devices/system/cpu/cpu$i/online`
            if [[ $online = 1 ]] ;then
                echo -n `cat /sys/devices/system/cpu/cpu$i/cpufreq/cpuinfo_cur_freq` >> $log_path
                echo -n , >> $log_path
                echo -n `cat /sys/devices/system/cpu/cpu$i/cpufreq/scaling_max_freq` >> $log_path
                echo -n , >> $log_path
                break;
            fi

            if [[ $i = 3 ]] ;then
                echo -n ' '  >> $log_path
                echo -n , >> $log_path
                echo -n ' '  >> $log_path
                echo -n , >> $log_path
            fi
        done;


        for i in 4 5 6 7
        do
            online=`cat /sys/devices/system/cpu/cpu$i/online`
            if [[ $online = 1 ]] ;then
                echo -n `cat /sys/devices/system/cpu/cpu$i/cpufreq/cpuinfo_cur_freq` >> $log_path
                echo -n , >> $log_path
                echo -n `cat /sys/devices/system/cpu/cpu$i/cpufreq/scaling_max_freq` >> $log_path
                echo -n , >> $log_path
                break;
            fi
            if [[ $i = 7 ]] ;then
                echo -n ' '  >> $log_path
                echo -n , >> $log_path
                echo -n ' '  >> $log_path
                echo -n , >> $log_path
            fi
        done;

        echo -n `cat /sys/devices/virtual/thermal/thermal_zone0/temp` >> $log_path
        echo -n , >> $log_path
        echo -n `cat /sys/devices/virtual/thermal/thermal_zone1/temp` >> $log_path
        echo -n , >> $log_path
        echo -n `cat /sys/devices/virtual/thermal/thermal_zone2/temp` >> $log_path
        echo -n , >> $log_path
        echo -n `cat /sys/devices/virtual/thermal/thermal_zone3/temp` >> $log_path
        echo -n , >> $log_path
        echo -n `cat /sys/devices/virtual/thermal/thermal_zone4/temp` >> $log_path
        echo -n , >> $log_path
        echo -n `cat /sys/devices/virtual/thermal/thermal_zone5/temp` >> $log_path
        echo -n , >> $log_path
        echo -n `cat /sys/devices/virtual/thermal/thermal_zone6/temp` >> $log_path
        echo -n , >> $log_path
        echo -n `cat /sys/devices/virtual/thermal/thermal_zone7/temp` >> $log_path
        echo -n , >> $log_path
		echo -n `cat /sys/devices/virtual/thermal/thermal_zone8/temp` >> $log_path
        echo -n , >> $log_path
        echo -n `cat /sys/module/qpnp_adc_voltage/parameters/therm_cpu` >> $log_path
        echo -n , >> $log_path
        echo -n `cat /sys/module/qpnp_adc_voltage/parameters/therm_cam` >> $log_path
        echo -n , >> $log_path

        if [ charge_mode -eq 1 ];then
            echo -n "ON" >> $log_path
        else
            echo -n "OFF" >> $log_path
        fi

        echo >> $log_path

        #get log file size
        TEMP=`ls -s $log_path`
        arr=(${TEMP})
        file_size=${arr[0]}

        if [ $file_size -ge $2 ];then
            mv $log_path $log_path".old.csv"
            file_size=0
        fi
        sync
        sleep $1
    done
#Ti log end
#/* DTS2015082203230 yinfenghang 20150822 end> */
#---------------------------------------------------------------------------------------------------------------------------------
elif [ $log_type -eq $log_type_ti_low ];then
#---------------------------------------------------------------------------------------------------------------------------------
#Ti log begin
    echo -n "Date  Time     Voltage Current SOC RM FCC II SI Temp FLAG Status Qmax ufrm frm uffcc ffcc ufsoc Reg[0] Reg[1] Reg[2] Reg[3] Reg[4] usbonline usbscope usbtype usbcurrentmax batterypresent hot_current_limit health status soc_user charging_enabled cpu0_scaling_cur_freq cpu0_scaling_max_freq cpu4_scaling_cur_freq cpu4_scaling_max_freq zone2_temp zone5_temp zone9_temp therm_cpu Mode" >> $log_path
#/* DTS2015032300312 zhaoxiaoli 20150323 end > */
    echo >> $log_path
    chmod 755 /data/log/chargelog/chargelog.txt
    while true
    do
        echo -n `date +%0m-%0e` >> $log_path
        echo -n ' ' >> $log_path
        echo -n `date +%H:%M:%S` >> $log_path
        echo -n ' ' >> $log_path

        echo -n `cat /sys/bus/i2c/drivers/ti,bq27510/ti-bms-prop/gaugelog` >> $log_path
        echo -n ' ' >> $log_path
        echo -n `cat /sys/devices/soc.0/78b8000.i2c/i2c-4/4-006b/power_supply/battery/ti-charger-prop/registers` >> $log_path
        echo -n ' ' >> $log_path

        echo -n `cat /sys/class/power_supply/usb/online` >> $log_path
        echo -n ' ' >> $log_path
        echo -n `cat /sys/class/power_supply/usb/scope` >> $log_path
        echo -n ' ' >> $log_path
        echo -n `cat /sys/class/power_supply/usb/type` >> $log_path
        echo -n ' ' >> $log_path
        echo -n `cat /sys/class/power_supply/usb/current_max` >> $log_path
        echo -n ' ' >> $log_path
        echo -n `cat /sys/class/power_supply/battery/present` >> $log_path
        echo -n ' ' >> $log_path
        echo -n `cat /sys/class/power_supply/battery/hot_current_limit` >> $log_path
        echo -n ' ' >> $log_path

        echo -n `cat /sys/class/power_supply/battery/health` >> $log_path
        echo -n ' ' >> $log_path
        echo -n `cat /sys/class/power_supply/battery/status` >> $log_path
        echo -n ' ' >> $log_path
        echo -n `cat /sys/class/power_supply/battery/capacity` >> $log_path
        echo -n ' ' >> $log_path
        echo -n `cat /sys/class/power_supply/battery/charging_enabled` >> $log_path
        echo -n ' ' >> $log_path

        echo -n `cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq` >> $log_path
        echo -n ' ' >> $log_path

        echo -n `cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq` >> $log_path
        echo -n ' ' >> $log_path

        echo -n `cat /sys/devices/system/cpu/cpu4/cpufreq/scaling_cur_freq` >> $log_path
        echo -n ' ' >> $log_path

        echo -n `cat /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq` >> $log_path
        echo -n ' ' >> $log_path

        echo -n `cat /sys/devices/virtual/thermal/thermal_zone2/temp` >> $log_path
        echo -n ' ' >> $log_path

        echo -n `cat /sys/devices/virtual/thermal/thermal_zone5/temp` >> $log_path
        echo -n ' ' >> $log_path

        echo -n `cat /sys/devices/virtual/thermal/thermal_zone9/temp` >> $log_path
        echo -n ' ' >> $log_path

        echo -n `cat /sys/module/qpnp_adc_voltage/parameters/therm_cpu` >> $log_path
        echo -n ' ' >> $log_path

        if [ charge_mode -eq 1 ];then
            echo -n "ON" >> $log_path
        else
            echo -n "OFF" >> $log_path
        fi

        echo >> $log_path

        #get log file size
        TEMP=`ls -s $log_path`
        arr=(${TEMP})
        file_size=${arr[0]}

        if [ $file_size -ge $2 ];then
            mv $log_path $log_path".old"
            file_size=0
        fi
        sync
        sleep $1
    done
#Ti log end
#---------------------------------------------------------------------------------------------------------------------------------
elif [ $log_type -eq $log_type_ti_only ];then
#---------------------------------------------------------------------------------------------------------------------------------
#Ti only log begin
    echo -n "Date  Time      charging_enabled health status Voltage Voltage_ocv  Battery_type Current Capacity TEMP FCC Reg[0] Reg[1] Reg[2] Reg[3] Reg[4] usbonline usbscope usbtype usbcurrentmax batterypresent hot_current_limit cpu0_scaling_cur_freq cpu0_scaling_max_freq cpu4_scaling_cur_freq cpu4_scaling_max_freq zone2_temp zone5_temp zone9_temp therm_cpu Mode" >> $log_path
    echo >> $log_path
    chmod 755 /data/log/chargelog/chargelog.txt
    while true
    do
        echo -n `date +%0m-%0e` >> $log_path
        echo -n ' ' >> $log_path
        echo -n `date +%H:%M:%S` >> $log_path
        echo -n ' ' >> $log_path
        echo -n `cat /sys/class/power_supply/battery/charging_enabled` >> $log_path
        echo -n ' ' >> $log_path
        echo -n `cat /sys/class/power_supply/battery/health` >> $log_path
        echo -n ' ' >> $log_path
        echo -n `cat /sys/class/power_supply/battery/status` >> $log_path
        echo -n ' ' >> $log_path
        echo -n `cat /sys/class/power_supply/battery/voltage_now` >> $log_path
        echo -n ' ' >> $log_path
        echo -n `cat /sys/class/power_supply/bms/voltage_ocv` >> $log_path
        echo -n ' ' >> $log_path
        echo -n `cat /sys/class/power_supply/bms/battery_type` >> $log_path
        echo -n ' ' >> $log_path
        echo -n `cat /sys/class/power_supply/battery/current_now` >> $log_path
        echo -n ' ' >> $log_path
        echo -n `cat /sys/class/power_supply/battery/capacity` >> $log_path
        echo -n ' ' >> $log_path
        echo -n `cat /sys/class/power_supply/battery/temp` >> $log_path
        echo -n ' ' >> $log_path
        echo -n `cat /sys/class/power_supply/bms/charge_full_design` >> $log_path
        echo -n ' ' >> $log_path

        echo -n `cat /sys/devices/soc.0/78b8000.i2c/i2c-4/4-006b/power_supply/battery/ti-charger-prop/registers` >> $log_path
        echo -n ' ' >> $log_path

        echo -n `cat /sys/class/power_supply/usb/online` >> $log_path
        echo -n ' ' >> $log_path
        echo -n `cat /sys/class/power_supply/usb/scope` >> $log_path
        echo -n ' ' >> $log_path
        echo -n `cat /sys/class/power_supply/usb/type` >> $log_path
        echo -n ' ' >> $log_path
        echo -n `cat /sys/class/power_supply/usb/current_max` >> $log_path
        echo -n ' ' >> $log_path
        echo -n `cat /sys/class/power_supply/battery/present` >> $log_path
        echo -n ' ' >> $log_path
        echo -n `cat /sys/class/power_supply/battery/hot_current_limit` >> $log_path
        echo -n ' ' >> $log_path

        echo -n `cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq` >> $log_path
        echo -n ' ' >> $log_path

        echo -n `cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq` >> $log_path
        echo -n ' ' >> $log_path

        echo -n `cat /sys/devices/system/cpu/cpu4/cpufreq/scaling_cur_freq` >> $log_path
        echo -n ' ' >> $log_path

        echo -n `cat /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq` >> $log_path
        echo -n ' ' >> $log_path

        echo -n `cat /sys/devices/virtual/thermal/thermal_zone2/temp` >> $log_path
        echo -n ' ' >> $log_path

        echo -n `cat /sys/devices/virtual/thermal/thermal_zone5/temp` >> $log_path
        echo -n ' ' >> $log_path

        echo -n `cat /sys/devices/virtual/thermal/thermal_zone9/temp` >> $log_path
        echo -n ' ' >> $log_path

        echo -n `cat /sys/module/qpnp_adc_voltage/parameters/therm_cpu` >> $log_path
        echo -n ' ' >> $log_path


        if [ charge_mode -eq 1 ];then
            echo -n "ON" >> $log_path
        else
            echo -n "OFF" >> $log_path
        fi

        echo >> $log_path

        #get log file size
        TEMP=`ls -s $log_path`
        arr=(${TEMP})
        file_size=${arr[0]}

        if [ $file_size -ge $2 ];then
            mv $log_path $log_path".old"
            file_size=0
        fi
        sync
        sleep $1
    done
#Ti only log end
#---------------------------------------------------------------------------------------------------------------------------------
else
#---------------------------------------------------------------------------------------------------------------------------------
#Qcom log begin
#print item name in this loop
cat $log_path | grep time
if [ $? -ne 0 ];then
    echo -n "date " >> $log_path
    echo -n "time " >> $log_path
	echo -n , >> $log_path
    for path in ${NODE_NAME[@]}
    do
        echo -n "$path" >> $log_path
        echo -n , >> $log_path
    done
    echo -n "MODE" >> $log_path
    echo >> $log_path
    chmod 755 /data/log/chargelog/chargelog.csv
fi

while :
do
    echo -n `date +%0m-%0e` >> $log_path
    echo -n ' ' >> $log_path
    echo -n `date +%H:%M:%S` >> $log_path
    echo -n , >> $log_path

    for path in ${NODE_NAME[@]}
    do
        echo -n `cat "$PS_PATH$path"` >> $log_path
        echo -n , >> $log_path
    done

    echo -n `cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_cur_freq` >> $log_path
    echo -n , >> $log_path

    echo -n `cat /sys/devices/virtual/thermal/thermal_zone2/temp` >> $log_path
    echo -n , >> $log_path

    echo -n `cat /sys/devices/virtual/thermal/thermal_zone4/temp` >> $log_path
    echo -n , >> $log_path

    echo -n `cat /sys/module/qpnp_adc_voltage/parameters/therm_cpu` >> $log_path
    echo -n , >> $log_path

    
    if [ charge_mode -eq 1 ];then
        echo -n "ON" >> $log_path
    else
        echo -n "OFF" >> $log_path
    fi
    
    echo >> $log_path

    #get log file size
    TEMP=`ls -s $log_path`
    arr=(${TEMP})
    file_size=${arr[0]}

    if [ $file_size -ge $2 ];then
        mv $log_path $log_path".old.csv"
        file_size=0
    fi
    sync
    sleep $1
done
#Qcom log end
#---------------------------------------------------------------------------------------------------------------------------------
fi
