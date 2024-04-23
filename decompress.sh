for i in $(find . -name "*.ko.*"); do 
    zstd -dfq $i --rm; 
done