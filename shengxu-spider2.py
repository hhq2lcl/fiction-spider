# fiction-spider
import re
import urllib.request
import sys
from bs4 import BeautifulSoup

#圣墟小说目录地址
url='http://www.biqiuge.com/book/4772/'
#user-agent
headers={'User-agent':'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.87 Safari/537.36'}
req=urllib.request.Request(url,headers=headers)
res=urllib.request.urlopen(req)
html=res.read().decode('gbk')
#创建BeautifulSoup对象
list_soup=BeautifulSoup(html,'lxml')
#搜索文档树，找出div标签中的id为list的所有子标签
chapters=list_soup.find_all('div',id="list")
#使用查询结果再创建一个BeautifulSoup对象,对其继续进行解析
download_soup=BeautifulSoup(str(chapters), 'lxml')#???????

name=list_soup.body.h1.string
#创建TXT文件夹
file=open(name+'.txt','w',encoding='utf-8')

#遍历dl标签下所有子节点
for child in download_soup.dl.children:
    if child !='\n':
        #爬取链接并下载链接内容
        if child.a != None:
            download_url=url+child.a.get('href')
            download_req=urllib.request.Request(url=download_url,headers=headers)
            download_res=urllib.request.urlopen(download_req)
            download_html=download_res.read().decode('gbk')
            texts_soup=BeautifulSoup(download_html,'lxml')
            texts=texts_soup.find_all('div')#(id='content',name='content')——如果用这个会出现‘'NoneType' object has no attribute 'text'’
            text_soup=BeautifulSoup(str(texts),'lxml')
            #将爬取内容写入文件
            file.write(text_soup.div.get_text())
file.close()
)
