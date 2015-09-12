%------------------------------Function THRJUDGE()------------------------------
function thrcc=thrjudge2(im,sunh,dnflag,fn,bflag,bx,by,radcc,bkcc,bsize)
%THRJUDGE: CRUCIAL FUNCTION. Judge the cloud or sky area with threshold
%	INPUT:
%		im:	the processed img
%		fn:	the processed img filename
%		dnflag:	day or night time flag 0 for day and 1 for night	
%		cc0:	the cloud-cover judged by experience method
%	OUTPUT:
%		ca:	the cloud area (px) that summed up
%		sa:	the sky area (px) that summed up
%		cc:	the cloud cover computed by 12 zones
%	SUBFUNCION:
%		READFILE:	Read the parameter files
%		COARSEMESH:	Caculate the theshold in Coarse Mesh(10*10 px)
%		SMOOTH:		Smooth the theshold in Coarse Mesh (mean 9 neighbourhood)
%		BILINEARITY:	Refine the theshold in every px with Bilinear Interpolation
%		BLACKORWHITE:	Divide the picture in to logical pic
%		CLEARFRAGMENT:	Clear the fragment whose area less than 100 px
%		CLOUDCOUNT:	Sum up the Cloud Area with weighted parameters
%		TESTCLEAR:	Exam whether the clear sky judged by experience is valid
%	EXAMPLE:
%		[ca,sa,cc,cc0]=expjudge(im,fn,dnflag,cc0)

%LOG:
%2012-08-14:	Complete
%2012-10-03:	Modify the description and comments
%2012-10-04:	Add dnflag
%2012-10-12:	Add TESTCLEAR module
%2013-01-22:	Modify the Algorithm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
	global standard;
	

	if bkcc<0 
		bkcc=0.5
	end
	sun_range=120;
	
	im0=im;
	X=im(:,:,3)==0;
	im(:,:,3)=double(im(:,:,3))+double(X);
	im=(double(im(:,:,1))./double(im(:,:,3)));
		
	fvis=fopen('parameter/tiny2.dat','r');
	line=fgetl(fvis);		%skip the title
	line=fgetl(fvis);
	vis=str2num(line(8:9));
	fclose(fvis);

	if dnflag
		range=200;	
	else	
		range=240;
	end

	im=imadjust(im,[0.75 1],[]);	
	%-------------------Brightness--------------------
	%-------------------2013-07-20--------------------

	%imtool(im);

	if sunh>0
		thr=0.79+(1-bkcc-radcc)*0.19;
		if (radcc==0)
			if(bkcc-radcc>0.5)
				thr=0.95;	
				if sunh>45
					sun_range=150;
				end
			end
			%if (bsize>400)
			%	for i =1:490
			%		for j=1:490	
			%			br=(round(sqrt((j-bx)^2+(i-by)^2)));
			%			r=(round(sqrt((i-245)^2+(j-245)^2)));				
			%			if(r<range)
			%				if (br>120)&(br<500)
			%					if(im0(i,j,1)<=im0(i,j,2))&(im0(i,j,1)<0.7)
			%						im(i,j)=thr-0.1;								
			%					end
			%				end
			%			end
			%		end
			%	end
			%end		
				
		end	
	else
		thr=0.98-bkcc*0.38
		for i =1:490
			for j=1:490
				r=(round(sqrt((i-245)^2+(j-245)^2)));		
				if(r<range)
					if (sum(im0(i,j,:))<0.6)
						im(i,j)=0.3;
					elseif(im(i,j)>0.6)&(im(i,j)<thr)
						im(i,j)=0.6;	
					elseif(im(i,j)<=0.6)
						im(i,j)=0.3;					
					end				
				end 
			end	
		end	
    end	

    if (thr>1)
        thr = 1
    elseif (thr<0)
        thr = 0
    end
	fprintf('        >>  Final Threshold:\t%6.2f\n',thr);

	imbw=im2bw(im,thr);

	imbw=clearfragment(imbw,sunh);

	imbw=imcomplement(imbw);

	imbw=clearfragment(imbw,sunh);	

	imbw=imcomplement(imbw);

	%dark=sum(im0,3)<1.86;
	%im=im+dark;

	thrcc=cloudcount(imbw,standard,fn,bflag,bx,by,range,sun_range,dnflag,sunh,vis);	

	
	imrb=cat(3,im,im,im);	%Matrix combanition
	%------body on!----------
	if sunh>0
		for i =1:490
			for j=1:490
				r=(round(sqrt((i-245)^2+(j-245)^2)));
				if(r<range)
					if (im(i,j)<thr)&(im(i,j)>0.6)
						imrb(i,j,:)=0.6;
					elseif im(i,j)<=0.6
						imrb(i,j,:)=0.5*imrb(i,j,:);				
					elseif im(i,j)<0.99
						imrb(i,j,:)=0.75;
					end
				end 
			end	
		end
	end
	if bflag
		for i=1:490
			for j=1:490
				r=(round(sqrt((i-245)^2+(j-245)^2)));				
				br=(round(sqrt((j-bx)^2+(i-by)^2)));				
				if(r<range+5)
					if r>=range+2
						imrb(i,j,3)=1;					
					end
					if(br<=sun_range)
						im0(i,j,3)=255;
					end
					if(abs(br-sun_range)<=1)
						im0(i,j,:)=[0 0 255];
						imrb(i,j,:)=[0 0 1];					
					end
					if(br<=3)
						im0(i,j,:)=[255 0 0];
						imrb(i,j,:)=[1 0 0];	
					end
				else
					imrb(i,j,:)=[0 0 0];	
				end
			end		
		end
	
	end
			
	imwrite(im0,'data/Before_Enhance_Gray.png');	%Before Red/Blue Process	
	imwrite(imrb,'data/After_Enhance_Gray.png');	%After Red/Blue Process


	%imtool(im0);
	%--------------------------------------------------
			

%------------------------------Function THEJUDGE-->CLEARFRAGMENT()------------------------------
function im=clearfragment(im0,sunh)
%CLEARFRAGMENT: Clear the fragment whose area less than 100 px
%	INPUT:
%		im0:	the picture that need to be clear fragment
%	OUTPUT:
%		im:	the picture that cleared the fragment
%	EXAMPLE:
%		im=clearfragment(im0)

%LOG:
%2012-08-14:	Complete
%2012-10-03:	Modify the description and comments
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
	if sunh>0
		minbody=49;
	else
		minbody=100;	
	end
	Liec=bwlabel(im0);						%Transform the 0-1pic into label pic
	stats=regionprops(Liec,'Area');					%Get every label's area
	idx=find([stats.Area]>minbody);					%Find the area of label that > 100
	im=ismember(Liec,idx);						%Delete the labels which area <=100	
	
	
%------------------------------Function THEJUDGE-->CLOUDCOUNT()------------------------------
function cc=cloudcount(im,standard,fn,bflag,bx,by,range,sun_range,dnflag,sunh,vis)
%CLOUDCOUNT:Sum up the Cloud Area with weighted parameters
%	INPUT:
%		im:	the picture that need to be count
%	OUTPUT:
%		cc:	cloud cover computed by 12 zones
%		ca:	the cloud area(px)
%		sa:	the sky area(px)
%	EXAMPLE:
%		[cc,ca,sa]=cloudcount(im)

%LOG:
%2012-08-14:	Complete
%2012-10-03:	Modify the description and comments
%2012-10-04:	Modify the algorithm to fit eye observation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 	

	ca=0;								%Cloud area(px)

	sa=0;								%Sky area(px)
	
	
	uca=0;								%Out range cloud area(px)	
	%Another scan, in order to sum up the weighted cloud area
	
	imd=double(im);
	imout=cat(3,imd,imd,imd);
	if bflag
		for i=1:490
			for j=1:490
				r=(round(sqrt((i-245)^2+(j-245)^2)));
				br=(round(sqrt((j-bx)^2+(i-by)^2)));				
				if(r<range)&(r>0)&(br>sun_range)			
					if(im(i,j)==1)
						ca=ca+standard(r);
						if (r>range-20)
							uca=uca+standard(r);
						end
					else
						sa=sa+standard(r);				
					end
				end
				if (r>=range)&(r<=range+5)
					imout(i,j,:)=[0 0 0];
				elseif(r>range)
					imout(i,j,:)=[1 1 1];		
				end
				if(abs(br-sun_range)<=1)&(r<=range)
					imout(i,j,:)=[0 0 1];					
				end
				if(br<=3)
					imout(i,j,:)=[1 0 0];	
				end
			end
		end
	else
		for i=1:490
			for j=1:490
				r=(round(sqrt((i-245)^2+(j-245)^2)));			
				if(r<range)&(r>0)			
					if(im(i,j)==1)
						ca=ca+standard(r);
						if (r>range-20)
							uca=uca+standard(r);
						end	
					else
						sa=sa+standard(r);				
					end
				end
				if (r>=range)&(r<=range+5)
					imout(i,j,:)=[0 0 0];
				elseif(r>range)
					imout(i,j,:)=[1 1 1];		
				end
			end
		end
	end
	if(sunh<-18)
		ucc=uca/(ca+sa);
		cc=ca/(ca+sa);
		if ((cc-ucc)<0.05)&(cc<0.3)&(vis<20)
			cc=0;
			for i=1:490
				for j=1:490
					r=(round(sqrt((i-245)^2+(j-245)^2)));
					if (r<=range)
						imout(i,j,:)=[0 0 0];
					elseif(r>range)
						imout(i,j,:)=[1 1 1];		
					end
				end
			end		
		else
			cc=cc-(1-cc)*ucc;				
		end
	else
		cc=ca/(ca+sa);	
	end
	
	if (bflag)&(cc>0.98)
		cc=0.98;	
	end

	loc=['data/divpic/',fn(6:13),'/div_',fn(6:17),'.png'];
	if(mod(str2num(fn(16:17)),10)==0)
		imwrite(imout,loc);					%Write the div pic
	end
	imwrite(imout,'data/div.png');

%------------------------------Function THEJUDGE-->TESTCLEAR()------------------------------
function cf=testclear(im)
%CLOUDCOUNT:exam whether the clear sky judged by experience is valid
%	INPUT:
%		im:	the picture that divided by threshold	
%	OUTPUT:
%		cf:	the clear flag with 1 for clear and 0 for not clear
%	EXAMPLE:
%		cf=cloudcount(im)

%LOG:
%2012-10-12:	Complete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

	cf=0;
	return;

	%{imo=imread('data/div.png');
	difim=xor(imo,im);					%the different area in div pic  
	[cc,ca,sa]=cloudcount(difim);				%count if invasive cloud/sky > 1 in 10 cover
	ch_sky=ca/(ca+sa);
	if (ch_sky<0.15)
		cf=1;	
	else
		cf=0;
	end%}
