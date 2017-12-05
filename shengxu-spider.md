# fiction-spider
import urllib.request
from bs4 import BeautifulSoup

url='http://www.biquge.com.tw/11_11850/'
headers={'User-Agent':'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.87 Safari/537.36'}
req=urllib.request.Request(url,headers=headers)
res=urllib.request.urlopen(req)
html=res.read().decode('gbk')

soup=BeautifulSoup(html,'lxml')

chapters=soup.find_all('div',id='list')
lists=BeautifulSoup(str(chapters),'lxml')

name=soup.h1.string

file=open(name+'.txt','w',encoding='utf-8')
for i in lists.dl.children:
    if i!='\n':
        if i.a!=None:
            list_url='http://www.biquge.com.tw'+i.a.get('href')
            list_req=urllib.request.Request(url=list_url,headers=headers)
            list_res=urllib.request.urlopen(list_req)
            list_html=list_res.read().decode('gbk')
            list_soup=BeautifulSoup(list_html,'lxml')
            chapter_name=list_soup.find('div',class_='bookname').text
            chapter=list_soup.find('div',id='content').text
            file.write(chapter_name)
            file.write(chapter)
file.close()
