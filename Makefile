readme:
	printf "(Frankly it's not the cleanest script ever... but it does the job very well.)\n\n" > README
	./*.sh --help >> README
