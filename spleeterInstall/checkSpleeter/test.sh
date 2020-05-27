#!/bin/bash
export LD_LIBRARY_PATH=./ffmpegKit/lib:${LD_LIBRARY_PATH}
testFileDir=$PWD/testFile
transcodeDir=$PWD/testResult/transcode
onlyH264Dir=$PWD/testResult/onlyH264
audioOutputDir=$PWD/testResult/audioOutput
newMp4Dir=$PWD/testResult/newMp4
logDir=$PWD/log
videoCount=0

#log path is $PWD/log
#if commod execute sucessed,it will return 0 else return 1
function log_info() { 
    DATE_N=$(date "+%Y-%m-%d %H:%M:%S")
    USER_N=$(whoami)
    echo "${DATE_N} ${USER_N} execute $0 [INFO] $@" >>$logDir/info.log #执行成功日志打印路径

}

function log_error() {
    DATE_N=$(date "+%Y-%m-%d %H:%M:%S")
    USER_N=$(whoami)
    echo -e "\033[41;37m ${DATE_N} ${USER_N} execute $0 [ERROR] $@ \033[0m" >>$logDir/error.log #执行失败日志打印路径
    echo "">>${logDir}/error.log 

}

function fn_log() {
    if [ $? -eq 0 ]; then
        log_info "$@ sucessed."
        echo -e "\033[32m $@ sucessed. \033[0m"
    else
        log_error "$@ failed."
        echo -e "\033[41;37m $@ failed. \033[0m"
        exit 1
    fi
}
trap 'fn_log "DO NOT SEND CTR + C WHEN EXECUTE SCRIPT !!!! "' 2

function Combine() {
    runTime "$1" "转码时间：" "$5" "转码"
    runTime "$2" "去除原声时间：" "$5" "去除原声"
    runTime "$3" "分离出背景音乐时间：" "$5" "分离出背景音乐"
    runTime "$4" "合并视频和背景音乐时间：" "$5" "合并视频和背景音乐"
}

function runTime() {
    startTime=$(date +%Y%m%d-%H:%M)
    startTime_s=$(date +%s)
    $1
    fn_log "$5 $4"
    endTime=$(date +%Y%m%d-%H:%M)
    endTime_s=$(date +%s)
    sumTime=$(($endTime_s - $startTime_s))
    fn_log "$3 $2:$sumTime seconds"
}

function checkDir()
{
    if [ ! -d $1 ]; then
        mkdir -p $1
    fi
}

#检查所必须的dir
function checkAllDir()
{
    checkDir "${transcodeDir}"
    checkDir "$onlyH264Dir"
    checkDir "$audioOutputDir"
    checkDir "$newMp4Dir"
    checkDir "${logDir}"
}

function startTest() 
{
    checkAllDir
    for item in `ls $1 | egrep -i '.mp4$|.mov$|.m4a$|.3gp$|3g2.$|.mj2$|.avi$|.wmv$|.rmvb$|.mkv$|.flv$'`; do #过滤视频格式
    fileName=$(echo ${item} | cut -d . -f1) #名字命名中不要含有.
    #获取视频时长
    # $PWD/ffmpegKit/getDurationOfVideo ${testFileDir}/${item} 
    # duration=`echo $?`

    startTimeAll=$(date +%Y%m%d-%H:%M)
    startTimeAll_s=$(date +%s)

    getConvertToMp4CMd="ffmpeg -y -i ${testFileDir}/${item} -c:v libx264 -x264opts keyint=8:min-keyint=8 -r 24 -c:a aac ${transcodeDir}/${fileName}.mp4"
    getH264OfVideoCmd="ffmpeg -y -i ${transcodeDir}/${fileName}.mp4 -c:v copy -an -sn -dn ${onlyH264Dir}/${fileName}.mp4"
    getBackMp3Cmd="spleeter separate -i ${testFileDir}/${item}  -c mp3 -o ${audioOutputDir}"
    getCombineCmd="ffmpeg -y -i ${onlyH264Dir}/${fileName}.mp4 -i ${audioOutputDir}/${fileName}/accompaniment.mp3 -filter_complex [1:a]aloop=loop=0:size=2e+09 -c:v copy ${newMp4Dir}/${fileName}.mp4"

    Combine "${getConvertToMp4CMd}" "${getH264OfVideoCmd}" "${getBackMp3Cmd}" "${getCombineCmd}" "${item}"
    endTimeAll=$(date +%Y%m%d-%H:%M)
    endTimeAll_s=$(date +%s)
    sumTimeAll=$(($endTimeAll_s - $startTimeAll_s))

    ((videoCount++))
    # echo "测试第${videoCount}个视频： ${item} 视频时长：${duration} seconds, 素材制作结束，花费总时间：${sumTimeAll} seconds" >>$logDir/info.log
    echo "测试第${videoCount}个视频： ${item} 素材制作结束，花费总时间：${sumTimeAll} seconds" >>$logDir/info.log
    echo "">>${logDir}/info.log         
    done
    echo "${testFileDir} 目录里的所有视频测试完毕">>${logDir}/info.log  
}

startTest "$testFileDir"


