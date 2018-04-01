#!/bin/bash
clear
echo "Добро пожаловать в программу резервного копирования ver:1.0"

#переменные пути
source_path=""
destination_path=""
full_destination_path=""
deleting_source_path=""

#переменные для лога
log_path="/var/log"
log_file="/loop_backup_log.txt"
how_in_log=" >> "

#файл крона /etc/crontab
loop_file="/etc/crontab"

#главное меню
introduction ()
{
local X=0
echo
echo "Пожалуйста, выберите действие:"
echo "1. Создать новую резервную копию"
echo "2. Отменить регулярную резервную копию"
echo "3. Выйти из программы"
read X
case ${X} in
"1" ) create_backup && echo "Спасибо, что пользуетесь программой";;
"2" ) delete_loop_backup ;;
"3" ) clear && echo "Спасибо за использование программы. Хорошего дня!" && exit ;;
 *  ) clear && echo "Неправильный ввод!"
esac
return
}

#пути бекапирования и единоразовый бэкап
create_backup ()
{
local X=0

while ((1 == 1))
do

clear
echo "Укажите путь к файлу или папке"
read source_path
echo
echo "Укажите путь хранения резервной копии "
read destination_path
echo

full_destination_path=$(echo -n "$destination_path"; echo -n "/"; echo -n "$source_path" | awk 'BEGIN {FS="/"} {print $NF}')
echo -n "Вы хотите создать резервную копию " && echo -n ${source_path} && echo -n " место хранения " && echo -n ${full_destination_path} && echo " ?"
read -p "Да(1) Нет(0) " X
if [ "$X" == "1" ]; then echo "Создаётся резервная копия..." && break; fi

echo
echo "Вы хотите повторить ввод?"
read -p "Да(1) Нет(0) " X
if [ "$X" == "0" ]; then return ; fi

done

echo
rsync -avzq --delete ${source_path} ${destination_path} && tar -czPf ${source_path} `date '+%d-%B-%Y's`.tar.gz ${destination_path} && echo "Резервное копирование выполнено успешно."

echo
echo "Вы хотите создавать резервную копию автоматически по расписанию?"
read -p "Да(1) Нет(0) " X
if [ "${X}" == "1" ] ; then create_loop_backup && echo && echo "Задание на регулярное резервное копирование добавлено!"; fi

return
}

#запись задания в крон
create_loop_backup ()
{
m='*'
h='*'
dom='*'
mon='*'
dow='*'
user='root'
command=""

echo
echo 'По умолчанию резервная копия создаётся каждую минуту, лог находится "/var/log/loop_backup_log.txt".'
echo 'На данный момент можно изменить только место хранения лога. Вы хотите изменить настройки?'
read -p "Да(1) Нет(0) " X
if [ "${X}" == "1" ] ; then read -p "Введте путь хранения лога: " log_path && echo && echo -n "Место хранения лога изменено на " && echo ${log_path}${log_file} ; fi

echo "#BEGIN loop backup script for ${source_path}" >> ${loop_file}

#очистка лога до 1000 строк
m="*/5"
command="cat ${log_path}${log_file} | tail -n 1000 > ${log_path}${log_file}_tmp.txt && mv -f ${log_path}${log_file}_tmp.txt ${log_path}${log_file}"
echo ${m}\ ${h}\ \ \ \ ${dom}\ ${mon}\ ${dow}\ \ \ ${user}\ \ \ \ ${command} >> ${loop_file} 

#основная команда - делает инкрементный бэкап, сравнивает на удалённые файлы, а так же формирует и записывает всё лог
m='*'
command="echo${how_in_log}${log_path}${log_file} && echo${how_in_log}${log_path}${log_file} && date -R ${how_in_log}${log_path}${log_file} && rsync -avz ${source_path} ${destination_path}${how_in_log}${log_path}${log_file} && echo${how_in_log}${log_path}${log_file} && rsync -avzn --delete ${source_path} ${destination_path} | grep -aF \"deleting \"${how_in_log}${log_path}${log_file}"
echo ${m}\ ${h}\ \ \ \ ${dom}\ ${mon}\ ${dow}\ \ \ ${user}\ \ \ \ ${command} >> ${loop_file}

#наблюдение1: СДЕЛАНО ЧЕРЕЗ ЗАДЕРЖКУ ПО ВРЕМЕНИ... быдлокодеры... Надо сделать либо флаг!!! либо конвеер с rsync!!! -- всё всё сделали конвеер
#наблюдение2: 2 echo не очень, можно склеить под одной датой всё и 2 echo делать только в rsync
#наблюдение3: diff ужасно работает при большой вложенности, большом объёме и большом количестве файлов!!! тупо не успевает за минуту, накапливается(10 стабильно запущенных diff за 30 мин) и херово работает -- сделали через rsync dry-run c с атрибутами -avzn --delete
#надо это как то решать
#command="sleep 20 && echo${how_in_log}${log_path}${log_file} && echo${how_in_log}${log_path}${log_file} && date -R ${how_in_log}${log_path}${log_file} &&  && echo Нет различий${how_in_log}${log_path}${log_file}"
#echo ${m}\ ${h}\ \ \ \ ${dom}\ ${mon}\ ${dow}\ \ \ ${user}\ \ \ \ ${command} >> ${loop_file}
echo -n "#END loop backup script for ${source_path} created: "  >> ${loop_file} && date -R >> ${loop_file}
return
}

#удаление записи из крона
delete_loop_backup ()
{
local X=0

while ((1 == 1))
do

clear
echo "Укажите путь к объекту резервное копирование которого хотите отменить"
read deleting_source_path

echo
echo -n "Вы хотите отменить регулярное резервное копирование " && echo ${deleting_source_path}
read -p "Да(1) Нет(0) " X
if [ "$X" == "1" ]; then echo "Производится удаление задания на регулярное резервное копирование..." && break; fi

echo
echo "Вы хотите повторить ввод?"
read -p "Да(1) Нет(0) " X
if [ "$X" == "0" ]; then echo "Запись не была удалена! Резервная копия будет создаваться по расписанию!" && return ; fi

done

while ((1 == 1))
do

N=$(grep -anxF \#BEGIN\ loop\ backup\ script\ for\ ${deleting_source_path} ${loop_file} | awk -F ":" '{print $1}'| tail -n 1)
if [ "$N" == "" ]; then echo "Запись успешно удалена! Резервная копия создаваться не будет!" && return ; fi

for (( j=1; j <= 4; j++ ))
do
sed -i ${N}d ${loop_file}
done

done
}

while ((1 == 1))
do
introduction
done
