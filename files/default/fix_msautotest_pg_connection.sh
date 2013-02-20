files=$(grep -rl "user=postgres" * | egrep "(map|include)")
for file in $files; do
    sed "s/user=postgres/user=vagrant/g" $file > $file.tmp
    mv $file.tmp $file
done
