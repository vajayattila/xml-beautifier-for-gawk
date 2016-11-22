#############################################################
# formatxml
# 1.2.0.2
# by Vajay Attila
# email vajay.attila@gmail.com
# 2013-2016
# Read a XML file and print out formatted XML source
#
# Script for gawk 
#############################################################

function ltrim(s) { sub(/^[ \t\r\n]+/, "", s); return s }
function rtrim(s) { sub(/[ \t\r\n]+$/, "", s); return s }
function trim(s)  { return rtrim(ltrim(s)); }
function rms(s) {
  wstr=s
  gsub(/[ \t]+/," ",wstr)
  return trim(wstr)
}
function rmalls(s) {
  wstr=s
  gsub(/[ \t\r\n]+/," ",wstr)
  return trim(wstr)
}
function rmnl(s) {
  wstr=s
  gsub(/[\r\n]+/,"",wstr)
  return trim(wstr)
}

function rmequalspaces(spar)
{
  gsub(" = ","=",spar)
  gsub(" =","=",spar)
  gsub("= ","=",spar)
  return spar
}

function rmsexceptstring(strpar)
{
	wstrlv=strpar
	wstrlv2=""
	wstrlv3=""
	poz=index(wstrlv, "\"");
	foundquote=0
	if(poz==0)
	{
		wstrlv2=wstrlv
	}
	arrcountlv=0
	delete arrlv
	while(poz!=0)	
	{
		foundquote=1
		wstrlv2=wstrlv2 substr(wstrlv, 0, poz-1)
		wstrlv=substr(wstrlv, poz+1, length(wstrlv))
		poz=index(wstrlv, "\"");	
		if(poz!=0)
		{
			arrcountlv++
			arrlv[arrcountlv]=substr(wstrlv, 1, poz)
			wstrlv2=wstrlv2 "\"" arrcountlv "\""
			wstrlv=substr(wstrlv, poz+1, length(wstrlv))
			poz=index(wstrlv, "\"");	
		}
	}
	if(foundquote==1)
	{
		wstrlv2=wstrlv2 wstrlv
	}
	wstrlv2=rms(wstrlv2)
	wstrlv=""
	poz=index(wstrlv2, "\"");  
	if(poz==0)
	{
		wstrlv=wstrlv2
	}
	while(poz!=0)	
	{
		wstrlv=wstrlv substr(wstrlv2, 0, poz)
		wstrlv2=substr(wstrlv2, poz+1, length(wstrlv2))	
		poz=index(wstrlv2, "\"");
		if(poz!="")
		{
			wstrlv3=substr(wstrlv2, 1, poz-1)
			wstrlv=wstrlv arrlv[wstrlv3]
			wstrlv2=substr(wstrlv2, poz+1, length(wstrlv2))	
			poz=index(wstrlv2, "\"");			
		}
	}
	if(foundquote==1)
	{
		wstrlv=wstrlv wstrlv2;
	}
	return wstrlv;
}
	

# xmltagtype return values: 
# 0 - Value and end tag
# 1 - Closed Comment Tag '<?'
# 2 - Left Open Comment Tag '<?'
# 3 - Closed Tag
# 4 - Open Tag 
# 5 - End Tag
# 6 - Left Open End Tag
# 7 - Left Open Multi Line Tag 
# 8 - Closed Comment Tag '<!--'
# 9 - Left Open Comment Tag '<!--'
# 10 - doctype tag '<!DOCTYPE'
# 11 - Left open doctype tag '<!DOCTYPE'
function gettagtype(commandpar)
{
  retval=0
  if(index(commandpar, "<?")!=0)
  {
    if(index(commandpar, "?>")!=0)
      retval=1
    else
      retval=2
      
  }
  else
  if(index(commandpar, "<!--")!=0)
  {
    if(index(commandpar, "-->")!=0)
      retval=8
    else
      retval=9
      
  }
  else
  if(index(commandpar, "<!DOCTYPE")!=0)
  {
    if(index(commandpar, ">")!=0)
      retval=10
    else
      retval=11
  }
  else
  if(index(commandpar, "<!")!=0)
  {
    if(index(commandpar, ">")!=0)
      retval=1
    else
      retval=2
      
  }
  else if(index(commandpar, "</")!=0) 
  {
    if(index(commandpar, ">")!=0)
      retval=5
    else
      retval=6
  }
  else if(index(commandpar, "<")!=0) 
  {
    if(index(commandpar, "/>")!=0)
      retval=3
    else if(index(commandpar, ">")!=0) 
      retval=4    
    else
      retval=7
  }
  
  return retval
}

function gettagtypename(tagtp)
{
  switch(tagtp)
  {
    case 0: 
      return "value and end tag";
    case 1: 
      return "closed comment tag";    
    case 2: 
      return "left open comment tag";        
    case 3: 
      return "closed tag";            
    case 4: 
      return "open tag";            
    case 5: 
      return "end tag";            
    case 6: 
      return "left open end tag";            
    case 7: 
      return "open multi line tag";            
	case 8:
      return "closed comment tag"
	case 9:{
        print "Left open comment tag not supported yet: " tagtp >> xmlinfofilename
		exit LEFT_OPEN_COMMENT_TAG_NOT_SUPPORTED
    } 
	case 10:
      return "doctype tag"
	case 11:{
        print "Left open doctype tag not supported yet: " tagtp >> xmlinfofilename
		exit LEFT_OPEN_DOCTYPE_TAG_NOT_SUPPORTED
	}
  }
}

function iscleancommand(spar)
{
  if(spar=="")
  {
    return 0
  }
  
  wstrlv=spar
  wstrlv=trim(wstrlv)
  return substr(wstrlv, 1, 1)=="<"
}

function getvaluefromnotcleancommand(spar)
{
  wstrlv=spar
  return substr(wstrlv, 1, index(wstrlv, "<")-1) 
}

function getcleancommandfromnotcleancommand(spar)
{
  wstrlv=spar
  return substr(wstrlv, index(wstrlv, "<"), length(wstrlv))
}

function tokenizefirstattribute()
{
  lvs=wtag
  lvfirstpoz=index(lvs, "\"");
  lvfoundattr=0
  if(lvfirstpoz!=0)
  {
	wtag=substr(lvs, 1, lvfirstpoz-1)
    lvs=substr(lvs, lvfirstpoz+1, length(lvs))
    lvfirstpoz=index(lvs, "\"");
    if(lvfirstpoz!=0)
    {
      attrcounter++
      wtag=wtag attrcounter substr(lvs, lvfirstpoz+1, length(lvs))
      attributes[attrcounter]="\"" substr(lvs, 1, lvfirstpoz)
	  checkstringvalue(attributes[attrcounter])
      lvfoundattr=1
    }
    else
    {
      print "Attribute not close in : " wtag >> xmlinfofilename
      exit ERROR_ATTR_NOT_CLOSE
    }
  }
  return lvfoundattr
}

function setlevelbytagtype_pre(l, ttype)
{
  lvlevel=l
  switch(ttype)
  {
    case 0: 
      lvlevel-- #value and end tag
      break
    case 1: 
      break #closed comment tag
    case 2: 
      break # left open comment tag
    case 3: 
      break # closed tag
    case 4: 
      break # open tag
    case 5: 
      lvlevel-- # end tag
      break
    case 6: 
      break # left open end tag
    case 7: 
      break #open multi line tag
  }
  return lvlevel
}

function setlevelbytagtype_post(l, ttype)
{
  lvlevel=l
  switch(ttype)
  {
    case 0: 
      break #value and end tag
    case 1: 
      break #closed comment tag
    case 2: 
      break # left open comment tag
    case 3: # closed tag
      break 
    case 4: # open tag
      lvlevel++ 
      break
    case 5: 
      break # end tag
    case 6: 
      break # left open end tag
    case 7: 
      break #open multi line tag
  }
  return lvlevel
}

function SearchBeginningsAndEndsForElemets()
{
  tagpos_lv=0
  for(i_lv=1;i_lv<=tagcounter;i_lv++)
  {
    switch(tags[i_lv, "type"])
    {
      case 1: #closed comment tag
      case 3: #closed tag 
      case 8: #closed comment tag	  
      case 10: #closed doctype tag	  	  
      {
        elementcounter++
        elements[elementcounter, "begintag"]=i_lv
        elements[elementcounter, "endtag"]=i_lv
        break
      }
      case 2: #left open comment tag
      case 4: #open tag
      case 7: #open multi line tag
      case 9: #left open comment tag  
      {
        elementcounter++
        elements[elementcounter, "begintag"]=i_lv
        elements[elementcounter, "endtag"]=0
        for(j_lv=i_lv+1;j_lv<=tagcounter&&elements[elementcounter, "endtag"]==0;j_lv++)
        {
          if(tags[i_lv, "level"]==tags[j_lv, "level"])
          {
            switch(tags[j_lv, "type"])
            {
              case 0: #value and end tag
              case 5: #end tag
              case 6: #left open end tag
                elements[elementcounter, "endtag"]=j_lv
                break
            }
          }
        }
        break
      }
    }
  }

}

function rmsftage(spar)
{
	sub(" />", "/>", spar)
	sub(" >", ">", spar)
	sub(" [?]>", "?>", spar)
	sub(" -->", "-->", spar)	
	return spar;
}

function checkstringvalue(strpar)
{
	countlv=split(strpar, arraylv, "<|>")		
	if(1<countlv)
	{
		print "Syntax error. Can't be < or > character in string value: " strpar >> xmlinfofilename
		exit SYNTAX_ERROR_CANT_BE_IN_STRING
	}
	return strpar;
}

function ScanTags()
{
  filename=ARGV[1]
  content=""
  tagcounter=0
  datacounter=0
  attrcounter=0
  elementcounter=0
  level=0
  delete tags
  delete datas
  delete attributes
  delete elements
  while(( getline line < filename ) > 0 ) {
    content=content line
    poz=index(content, ">")
    if( substr(line,length(line),1)!=">" )
    {
      content=content "\n"
    }
    while(poz!=0) 
    {
      command=substr(content, 1, poz)
      content=substr(content, poz+1, length(content))

      if(!iscleancommand(command))
      {
        wvalue=getvaluefromnotcleancommand(command)
        wtag=rms(getcleancommandfromnotcleancommand(command))
		wtag=rmsftage(wtag)
        tagcounter++
        datacounter++
        datas[datacounter]=checkstringvalue("\"" wvalue "\"")
        level=setlevelbytagtype_pre(level, gettagtype(wvalue))
        tags[tagcounter,"data"]=datacounter
        tags[tagcounter,"tag"]=rmequalspaces(rmsftage(rmalls(wtag)))
        tags[tagcounter,"type"]=gettagtype(wvalue)
        tags[tagcounter,"level"]=level
        level=setlevelbytagtype_post(level, gettagtype(wvalue))        
      }
      else
      {
        lvtagtype=gettagtype(command)
		wtag=rmsexceptstring(command)
		#wtag=rms(command)
		#print wtag
		wtag=rmsftage(wtag)
        tagcounter=tagcounter+1
        while(tokenizefirstattribute()!=0)
        {
          #do notthing
        };
        level=setlevelbytagtype_pre(level, lvtagtype)
        tags[tagcounter,"tag"]=rmequalspaces(rmsftage(rmalls(wtag)))
        tags[tagcounter,"type"]=lvtagtype
        tags[tagcounter,"level"]=level
        level=setlevelbytagtype_post(level, lvtagtype)        
        
      }
      poz=index(content, ">")
    }
  }  

  # search begin and end tags for elements
  SearchBeginningsAndEndsForElemets()
}

function syntaxcheck(tagpar)
{
	delete resultarray
	resultcount=0
	countlv=split(tagpar, arraylv, " |>|-->|?>|/>")	
	if(countlv<2)
	{
		print countlv
		print "Syntax error in tag: " tagpar >> xmlinfofilename
		exit SYNTAX_ERROR_IN_TAG
	}
	for(ilv=1;ilv<=countlv; ilv++) 
	{	
		if(ilv!=1&&ilv!=countlv)
		{
			resultcount++
			pozlv=index(arraylv[ilv], "=")
			if(pozlv==0)
			{
				print "Syntax error in attribute: " arraylv[ilv] >> xmlinfofilename
				exit SYNTAX_ERROR_IN_ATTRIBUTE
			}
			resultarray[resultcount, "name"]=substr(arraylv[ilv], 1, pozlv-1)
			resultarray[resultcount, "value"]=substr(arraylv[ilv], pozlv+1, length(arraylv[ilv]))
			if(resultarray[resultcount, "name"]=="")
			{
				print "Syntax error. Attribute name not found: " arraylv[ilv] >> xmlinfofilename
				exit SYNTAX_ERROR_ATTR_NAME_NOT_FOUND
			}
			if(resultarray[resultcount, "value"]=="")
			{
				print "Syntax error. Attribute value not found: " arraylv[ilv] >> xmlinfofilename
				exit SYNTAX_ERROR_ATTR_VALUE_NOT_FOUND
			}
		}
	}
}

function getelementname(tagpar)
{
	countlv=split(tagpar, arraylv, "<|</|<?|<!|>|/>|?>| ")		
	retval=arraylv[2]
	
	if(countlv<1)
	{
		print "Syntax error. Element name not found in: " tagpar >> xmlinfofilename
		exit SYNTAX_ERROR_ELEMENT_NAME_NOT_FOUND;
	}
	if(index(arraylv[2], "?")==1)
	{
		retval=substr(arraylv[2], 2, length(arraylv[2]))
	}
	if(index(arraylv[2], "--")==1)
	{
		split(tagpar, arraylv, "<!--|-->")
		retval="###comment###" arraylv[2]
	}
	if(index(arraylv[2], "DOCTYPE")==1)
	{
		split(tagpar, arraylv, "<!|>")
		retval="###doctype###" arraylv[2]
	}
	return retval;
}

function tabbylevel(levelpar)
{
	retstrlv=""
	for(ilv=1;ilv<=levelpar;ilv++)
	{
		retstrlv=retstrlv TABS
	}
	return retstrlv
}

function rmquotmarks(strpar)
{
  gsub("\"","",strpar)	
  return rtrim(strpar)
}

function parsedoctype(pstr)
{
	retval_parsedoctype=""
	count_parsedoctype=split(pstr, arr_parsedoctype, " ")
	for(i_parsedoctype=1;i_parsedoctype<=count_parsedoctype;i_parsedoctype++)
	{
		parsedoctype_tstr=attributes[arr_parsedoctype[i_parsedoctype]]
		if(parsedoctype_tstr)
		{
			retval_parsedoctype=retval_parsedoctype " " parsedoctype_tstr	
		}
		else
		{
			retval_parsedoctype=retval_parsedoctype " " arr_parsedoctype[i_parsedoctype]
		}
	}
	return retval_parsedoctype
}

BEGIN{
  xmlinfofilename="xmlinfo.txt"
  APPNAME="XML beautifier for Gawk" 
  APPVERSION="1.2.0.2" 
  APPAUTHOR="Vajay Attila" 
  APPEMAIL="vajay.attila@gmail.com" 
  print APPNAME " By " APPAUTHOR " (" APPEMAIL ")" "\nVersion: " APPVERSION "\n" > xmlinfofilename	
  print "XML informations:" > xmlinfofilename	
  print "" >> xmlinfofilename	
  ERROR_ATTR_NOT_CLOSE=-1
  SYNTAX_ERROR_IN_TAG=-2
  SYNTAX_ERROR_IN_ATTRIBUTE=-3
  SYNTAX_ERROR_ATTR_NAME_NOT_FOUND=-4
  SYNTAX_ERROR_ATTR_VALUE_NOT_FOUND=-5
  SYNTAX_ERROR_ELEMENT_NAME_NOT_FOUND=-6
  SEMANTIC_ERROR_BEGIN_AND_END_NOT_MATCH=-7
  SYNTAX_ERROR_CANT_BE_IN_STRING=-8 
  UNKNOWN_TAG_TYPE=-9 
  LEFT_OPEN_COMMENT_TAG_NOT_SUPPORTED=-10
  LEFT_OPEN_DOCTYPE_TAG_NOT_SUPPORTED=-11
  TABS="  "
  ScanTags()  
  
  print "Number of tags: " tagcounter >> xmlinfofilename
  for(i=1;i<=tagcounter;i++)
  {
    print "No." sprintf("%010d", i) " level: " tags[i, "level"] " type: " sprintf("%-30s", gettagtypename(tags[i,"type"])) " tag: " tags[i,"tag"] " data: " tags[i,"data"] >> xmlinfofilename
  }
  print "" >> xmlinfofilename
  print "Number os datas: " datacounter >> xmlinfofilename
  for(i=1;i<=datacounter;i++)
  {
    print "No." sprintf("%010d", i) " value: " datas[i] >> xmlinfofilename
  }
  print "" >> xmlinfofilename
  print "Number of attributes: " attrcounter >> xmlinfofilename
  for(i=1;i<=attrcounter;i++)
  {
    print "No." sprintf("%010d", i) " value: " attributes[i] >> xmlinfofilename
  }

  print "" >> xmlinfofilename
  print "Number of elements: " elementcounter >> xmlinfofilename
  for(i=1;i<=elementcounter;i++)
  {
	# semantic check
	elements[i, "begintagname"]=getelementname(tags[elements[i, "begintag"], "tag"]);
	elements[i, "endtagname"]=getelementname(tags[elements[i, "endtag"], "tag"]);	
	if(index(elements[i, "begintagname"], "###comment###")==1)
	{
		tstr=elements[i, "begintagname"]	
		elements[i, "begintagname"]=" " trim(substr(tstr, length("###comment###")+1)) " "
		elements[i, "endtagname"]=" " trim(substr(tstr, length("###comment###")+1)) " "
	}
	else if(index(elements[i, "begintagname"], "###doctype###")==1)
	{
		tstr=elements[i, "begintagname"]	
		tstr=substr(tstr, length("###doctype###")+1)
		tstr=trim(parsedoctype(tstr))
		elements[i, "begintagname"]=tstr
		elements[i, "endtagname"]=tstr
	}
	else
	{
		if(elements[i, "begintagname"]!=elements[i, "endtagname"])
		{
			print "Semantic error. Begin and end tag name not match: " tags[elements[i, "begintag"], "tag"] " and " tags[elements[i, "endtag"], "tag"]>> xmlinfofilename
			exit SEMANTIC_ERROR_BEGIN_AND_END_NOT_MATCH;		
		}
		print "No." sprintf("%010d", i) " begintag: " elements[i, "begintag"] " endtag: " elements[i, "endtag"] " begintagname: " elements[i, "begintagname"] " endtagname: " elements[i, "endtagname"] >> xmlinfofilename
		if(tags[elements[i, "endtag"], "data"]!="")
		{
			elements[i, "data"]=tags[elements[i, "endtag"], "data"];
			print "  " "Data = " elements[i, "data"] >> xmlinfofilename
		}
		# syntax check
		syntaxcheck(tags[elements[i, "begintag"], "tag"])
		elements[i, "attributes", "count"]=resultcount
		arraycount=elements[i, "attributes", "count"]
		if(0<arraycount)
		{
			print "  " "Number of attributes: "  arraycount >> xmlinfofilename
			for(j=1;j<=arraycount;j++)
			{
				elements[i, "attributes", j, "name"] = resultarray[j, "name"] 
				elements[i, "attributes", j, "value"] = resultarray[j, "value"]
				print "  " "  " elements[i, "attributes", j, "name"] " = " elements[i, "attributes", j, "value"] >> xmlinfofilename
			}
		}
	}
  }
  # dump xml
  ORS=""  
  for(i=1;i<=tagcounter;i++)
  {
	for(j=1;j<=elementcounter;j++)
	{
		if(elements[j, "begintag"]==i||elements[j, "endtag"]==i)
		{
			if(elements[j, "begintag"]==elements[j, "endtag"])
			{
				if(tags[elements[j, "begintag"], "type"]==1 ) # comment '<?'
				{
					beglv="<?"
					endlv="?>\n" 
				}
				else if(tags[elements[j, "begintag"], "type"]==8 ) # comment '<!--'
				{
					beglv="<!--"
					endlv="-->\n" 
				}
				else if(tags[elements[j, "begintag"], "type"]==10 ) # doctype
				{
					beglv="<!"
					endlv=">\n" 
				}
				else
				{
					beglv="<"
					endlv="/>\n"
				}
				attrstrlv=""
				for(k=1;k<=elements[j, "attributes", "count"];k++)
				{
					attrstrlv=attrstrlv " " elements[j, "attributes", k, "name"] "=" attributes[elements[j, "attributes", k, "value"]]
				}
			    print tabbylevel(tags[elements[j, "begintag"], "level"]) beglv elements[j, "begintagname"] attrstrlv endlv
			}
			else if(elements[j, "begintag"]==i)
			{
				if(tags[elements[j, "begintag"], "type"]==1 ) # comment
				{
					beglv="<?"
					endlv="?>\n"
				}
				else if(tags[elements[j, "begintag"], "type"]==8 ) # comment '<!--'
				{
					beglv="<!--"
					endlv="-->\n" 
				}
				else if(tags[elements[j, "begintag"], "type"]==10 ) # doctype
				{
					beglv="<!"
					endlv=">\n" 
				}
				else
				{
					beglv="<"
					tabstr=tabbylevel(tags[elements[j, "begintag"], "level"])					
					if(elements[j, "data"]=="")
					{
						endlv=">\n"
					}
					else
					{
					    endlv=">"
					}
				}
				attrstrlv=""
				for(k=1;k<=elements[j, "attributes", "count"];k++)
				{
					attrstrlv=attrstrlv " " elements[j, "attributes", k, "name"] "=" attributes[elements[j, "attributes", k, "value"]]
				}
			    print tabstr beglv elements[j, "begintagname"] attrstrlv endlv 
			}else if(elements[j, "endtag"]==i)
			{
				if(elements[j, "data"]=="")
				{
					tabstr=tabbylevel(tags[elements[j, "endtag"], "level"])
				}
				else
				{
					tabstr=""
				}
				if(tags[elements[j, "endtag"], "type"]==1 ) # comment
				{
					beglv="<?"
					endlv="?>\n"
				}
				else
				if(tags[elements[j, "endtag"], "type"]==8 ) # comment
				{
					beglv="<!--"
					endlv="-->\n"
				}
				else
				{
					beglv="</"
					endlv=">\n"
				}
			    print tabstr rmquotmarks(datas[elements[j, "data"]]) beglv elements[j, "endtagname"] endlv
			}
		}
	}
  }
  print "\nEnd." >> xmlinfofilename
  
}
{
}
END{
    
}