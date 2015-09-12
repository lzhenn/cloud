%------------------------------Function EXPJUDGE()------------------------------
function [expcc,expdelta]=expjudge(fn,im,imo)

	expcc=-1;
	expdelta=0;
	n(9)=0;
	m(9)=0;								%store mean
	v(9)=0;								%store variance
	cc0=-1;

	for x=1:490										
		for y=1:490
			r=(round(sqrt((x-245)^2+(y-245)^2)));	
			if(r<200)
				if(x<=244)&(y>=245)			%I and Y+
					q=1;
				elseif(x<=245)&(y<=244)			%II and X-
					q=2;
				elseif(x>=246)&(y<=245)			%III and Y-
					q=3;
				elseif(x>=245)&(y>=246)			%IV and X+
					q=4;
				end
				if(r<=80)
					q=9;				%Inner area
				elseif(r>150)
					q=q+4;				%Outer area
				end
				n(q)=n(q)+1;
				m(q)=m(q)+double(im(x,y));
			end
		end
	end
	
	m=m./n;
	
	for x=1:490
		for y=1:490
			r=(round(sqrt((x-245)^2+(y-245)^2)));	
			if(r<200)
				if(x<=244)&(y>=245)			%I and Y+
					q=1;
				elseif(x<=245)&(y<=244)			%II and X-
					q=2;
				elseif(x>=246)&(y<=245)			%III and Y-
					q=3;
				elseif(x>=245)&(y>=246)			%IV and X+
					q=4;
				end
				if(r<=80)
					q=9;				%Inner area
				elseif(r>150)
					q=q+4;				%Outer area
				end
				v(q)=v(q)+(double(im(x,y))-m(q))*(double(im(x,y))-m(q));
			end
		end
	end

	v=v./n;
	if(m(9)<175)
		[expcc,expdelta]=sample(1,fn,m,v,imo);
	elseif(m(9)>180)
		[expcc,expdelta]=sample(0,fn,m,v,imo);
	end

%------------------------------Function EXPJUDGE-->SAMPLE()------------------------------
function [cc0,expdelta]=sample(flag,fn,m,v,imo)
%SAMPLE: Read the file in 0/10 CC Samples to judge the sky condition
%	INPUT:
%		flag:	the sign with 0 for Clear Possibility 1 for Overcast Possibility
%		m:	mean vector of 9 Area
%		v:	variance vector of 9 Area
%	OUTPUT:
%		cc0:	the result of judgement
%	EXAMPLE:
%		cc0=sample(1,m,v)

%LOG:
%2012-10-06:	Complete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%	
	expdelta=0;	
	if flag==1
		fid=fopen('parameter/Overcast/Overcast_Exp.txt','r');	
	else
		fid=fopen('parameter/Clear/Clear_Exp.txt','r');		
	end	
	cc0=-1;
	ln=1;
	pass=[];
	while(~feof(fid))
		line=fgetl(fid);
		if(mod(ln,3)==2)
			Ms(1:9,fix(ln/3)+1)=sscanf(line,'%f');		%Column for 9 Area Mean of each pic, Row for each pic	
		elseif(mod(ln,3)==0)			
			Vs(1:9,ln/3)=sscanf(line,'%f');
		end
		ln=ln+1;
	end
	fclose(fid);
	for i=1:fix(ln/3)
		pass(i)=0;			
		for j=1:9
			if (abs((m(j)-Ms(j,i))/Ms(j,i))<=0.05)&(abs((v(j)-Vs(j,i))/Vs(j,i))<=0.5)
				pass(i)=pass(i)+1;				
			end						
		end
	end
	pass
	if (max(pass)>=5)					%If 6 or more Areas pass the test, we believe it can be judged as Clear or Overcast Sky Condition
		if flag==1			
			cc0=1;	
			imwrite(imo,['/home/eesael/wx/cloud/parameter/Overcast_Sample/Org_',fn(6:15),'.png']);	
		else
			if(max(pass)>5)
				cc0=0;
				imwrite(imo,['/home/eesael/wx/cloud/parameter/Clear_Sample/Org_',fn(6:15),'.png']);
			end		
		end
	elseif(max(pass)>=2)
		if flag==1
			expdelta=0.1+max(pass)*0.05;		
		else
			expdelta=-0.1-max(pass)*0.05;
		end
	else
		if flag==1
			expdelta=0.1;
		else
			expdelta=-0.1;
		end
	end
	
