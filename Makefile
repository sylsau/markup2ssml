readme:
	printf "(Frankly it's not the cleanest script ever... but it does the job very well.)\n\n" > README
	./*.sh --help >> README
	sed "s/MARKUP FORMAT/MARKUP FORMAT\n\tSee Example\/ directory for a look at a fully marked-up text and its resulting SSML conversion./" -i README
