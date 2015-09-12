%------------------------------Function READIMG()------------------------------
function [fn,im]=readimg()
%READIMG: Read the newest 'jpg' file of CAM8 and do the geometrical process
%	INPUT:
%		NONE
%	OUTPUT:
%		im: the newest img that read from CAM8,which take up 491*491*3B in memory after geometrical process 
%		fn: the filename of the newest img, e.g. 'ch01_20121003000037.jpg'. IF FAILED,WITH RETURN 'empty' 
%	EXAMPLE:
%		[im,fn]=readim()

%LOG:
%2012-08-14:	Complete
%2012-10-02:	Modify the BUG FIX module to fit function module
%2012-10-03:	Modify the description and comments
%2012-12-08:	Rewrite the process of getting dir of ch01
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 	

	i=-5;								%5min foreward
	while(i<10)
		dirdate=datevec(datestr(now-60*i/86400));				%get i min before now on sever into a vector
		today=[int2str(dirdate(1)),full(dirdate(2)),full(dirdate(3))];
		ddname = ['../../archive/cam_src/data/ch01/',today,'/jpg/'];		%date dir name
		if(exist(ddname))							%dir name online
			file=dir([ddname,'/ch01_',today,full(dirdate(4)),full(dirdate(5)),'*.jpg']);	% try to dir file name	
			%file=dir([ddname,'ch01_20130718142025.jpg']);
			fn=[ddname,file.name];
			if(strcmp(fn,ddname)==0)	%file is existing!
				break;
			end	
		end
		i=i+1;
	end
	if(i>10)
		fn='';
		return;
	end
	try		
		im = imread(fn);
	catch
		fprintf('SYSTEM  >>  Info:Image format ruined\n\n');	
		fn='';
		return	
	end	
	
	fn=file.name;
	im = imresize(im, [527 704]);					%Change the size of picture
	im=im(21:510,109:598,:);					%Cut out the interesting part

	for i=1:489
		for j=1:489
			r=(round(sqrt((i-245)^2+(j-245)^2)));		
			if(r> 245)
				im(i,j,:)=[0 0 0];
			elseif(r==245)
				im(i,j,:)=[255 0 0];
			end
		end
	end
	imwrite(im,'data/Before_Enhance_RGB.png');
	if(exist(['data/divpic/',fn(6:13)])==0)		%If there is no such dir,make it
		mkdir('data/divpic/',fn(6:13));	
	end

function str=full(x)
%FULL:Fulfill the one num to format as '0X' such as '05'  
%	INPUT:
%		x:	the number that need to be fulfilled
%	OUTPUT:
%		str:	the filled string as '02'
%	EXAMPLE:
%		str=full(x)

%LOG:
%2012-10-04:	Complete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	if(x<10)
		str=['0',int2str(x)];	
	else	
		str=int2str(x);
	end
				
