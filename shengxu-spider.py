import urllib.request
from bs4 import BeautifulSoup
#圣墟小说目录地址
url='http://www.biquge.com.tw/11_11850/'
#User-agent
headers={'User-Agent':'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.87 Safari/537.36'}
req=urllib.request.Request(url,headers=headers)
res=urllib.request.urlopen(req)
html=res.read().decode('gbk')
#创建BeautifulSoup对象
soup=BeautifulSoup(html,'lxml')
#搜索文档树，找出div标签中的id为list的所有子标签
chapters=soup.find_all('div',id='list')
#使用查询结果再创建一个BeautifulSoup对象,对其继续进行解析
lists=BeautifulSoup(str(chapters),'lxml')
#创建TXT文件夹
name=soup.h1.string
file=open(name+'.txt','w',encoding='utf-8')
#遍历dl标签下所有子节点
for i in lists.dl.children:
    if i!='\n':
        if i.a!=None:
            #爬取链接并下载链接内容
            list_url='http://www.biquge.com.tw'+i.a.get('href')
            list_req=urllib.request.Request(url=list_url,headers=headers)
            list_res=urllib.request.urlopen(list_req)
            list_html=list_res.read().decode('gbk')
            list_soup=BeautifulSoup(list_html,'lxml')
            chapter_name=list_soup.find('div',class_='bookname').text
            chapter=list_soup.find('div',id='content').text
            #将爬取内容写入文件
            file.write(chapter_name)
            file.write(chapter)
file.close()
