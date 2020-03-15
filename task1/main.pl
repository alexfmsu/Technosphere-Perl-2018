# 1. Уникальные символы в ssh ключе (* только в ключе)
#
# - вывести количество уникальных символов:
perl -F"/\s/" -E '%h = map{$_, 1} split //, $F[1]; say scalar keys %h' ~/.ssh/id_rsa.pub

# - вывести уникальные символы:
perl -F"/\s/" -E '%h = map{$_, 1} split //, $F[1]; say sort keys %h' ~/.ssh/id_rsa.pub

# - вывести уникальные символы и количество раз, сколько встретилось:
perl -MDDP -F"/\s/" -E '$h{$_}++ for split //, $F[1]; p %h' ~/.ssh/id_rsa.pub
# or
perl -F"/\s/" -E '$h{$_}++ for split //, $F[1]; for(sort keys %h){say "$_: $h{$_}"}' ~/.ssh/id_rsa.pub

# 2. Вывести список пользователей, у которых шелл bash (passwd)
#
perl -F':' -naE 'say $F[0] if $F[-1] =~ /bash$/' /etc/passwd

# 3. Посчитать кол-во пустых строк в файле и убрать их (-i)
#
perl -i -nE '/^\s+$/ ? $n++ : print; END {say $n++}' filename
# or
perl -i -lnE '/^\s*$/ ? $n++ : say; END{say $n++}' filename
# or
perl -i -nE '/\S/ ? print : $n++; END{say $n++}' filename
# or
perl -i -lnE '/\S/ ? say : $n++; END{say $n++}' filename
#
# ($n++ <=> 0+$n)

# 4. Вывести, что и кем было установлено на машине (yum history)
#
sudo yum history | perl -F'/\|/' -anE 'if($F[3]=~/install/i && $F[0]=~/^\s*(\d+)/){ for(`sudo yum history info $1`){ $h{$F[1]}{$+{pkg}}="" if /^\s*Установить\s+(?<pkg>\S+)/}}; END {$,="\n\t"; for(keys %h){ say; print "\t"; say keys %{$h{$_}}}}'