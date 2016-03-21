#' @title Write encrypted data frame to file
#' 
#' @param df A \code{\link{data.frame}} to encrypt and write. 
#' @param filename Location to save or load encrypted binary file
#' @param key A secret key as a character string value. Must be <= 32 characters in length
#' 
#' @description
#' WARNING: Do not use for security critical applications. I am not a security expert. 
#' This is for low-security applications only.
#' 
#' This function encrypts and writes a data frame. It tries to be fairly efficient and can 
#' encrypt and write fairly large files (~ few seconds with ~500k rows). It makes assumptions
#' that could cause problems right now (default escaping and quoting from \code{\link{write.csv}})
#' used. 
#' 
#' @seealso \code{\link{read_aes}}, derived from this post: 
#' \url{http://stackoverflow.com/questions/25318800/how-do-i-read-an-encrypted-file-from-disk-with-r}
#' 
#' @importFrom digest AES
#' 
#' 
#' @export
write_aes = function(df, filename, key) {
	
	#append NUL to key to get it to 16 or 32 length
	key = c(as.raw(rep(0,16-nchar(key)%%16)), charToRaw(key))
	
	#switched to anonymous file for speed
	zz = file()
	write.csv(df, zz, row.names=F)
	out <- paste(readLines(zz), collapse="\n")
	close(zz)
	
	raw <- charToRaw(out)
	raw <- c(raw, as.raw(rep(0,16-length(raw)%%16)))
	aes <- AES(key, mode="ECB")
	
	writeBin(aes$encrypt(raw), filename)  
}

#' @title read encypted data frame from file
#' 
#' @inheritParams write_aes
#' 
#' @description 
#' WARNING: Do not use for security critical applications. I am not a security expert. 
#' This is for low-security applications only.
#' 
#' This unencrypts and reads a file written with \code{\link{write_aes}}. Uses defaults for
#' \code{\link{write.csv}}. This could cause issues with character columns with odd characters.
#' 
#' @seealso \code{\link{write_aes}}.
#' 
#' @importFrom digest AES
#' 
#' @export
read_aes = function(filename, key) {
	
	#turn string key into RAW type and append NUL until it is right length
	key = c(as.raw(rep(0,16-nchar(key)%%16)), charToRaw(key))
	
	#get size of file for readBin buffer
	fsize = file.info(filename)$size
	
	#buffer input length by 100 bytes
	dat <- readBin(filename, "raw", n=(fsize+100))
	aes <- AES(key, mode="ECB")
	raw <- aes$decrypt(dat, raw=TRUE)
	#remove NUL characters introduced by 16 byte padding above
	txt <- rawToChar(raw[raw>0])
	read.csv(text=txt) #maybe switch to serialize/unserialize later
}

