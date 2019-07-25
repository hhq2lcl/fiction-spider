from bs4 import BeautifulSoup
import urllib.request
import threading

import _thread

import re
import os
import time
import sys
import ssl
import random
url='https://www.biqiuge.com/paihangbang/'
headers ={'User-Agent':'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36'}
#思路：
#1、一本一本的爬取，根据书名号：【https://www.biqiuge.com/paihangbang/book】+【4772】+【章节】
#http://localhost:8888/notebooks/Untitled.ipynb

#BeautifulSoup解析网址
def analysis_url(url):
    req=urllib.request.Request(url,headers=headers)
    re=urllib.request.urlopen(req)
    text=re.read()
    html=BeautifulSoup(text,'html.parser')
    return html

#获取小说url
def get_book_url(url):
    html=analysis_url(url)
    book_id=[b.a.get('href')[6:-1] for b in html.find_all('li')]
    book_id1=','.join(book_id)
    book_id2=re.findall(r'\d+',book_id1)
    book_id3=[url[:24]+'book/'+id for id in book_id2]
    return book_id3

#注释：这里的url是某一本小说的url
def get_chapter_url(url):
    html=analysis_url(url)
    story_name=html.h2.get_text()+'.txt'
    chapter_url_1=[url[:23]+c.a.get('href') for c in html.find_all('dd')][6:]
    chapter_url=chapter_url_1[:10]#################################################################【筛选下载多少章节】
    return (story_name,chapter_url)

#注释：这里的url是章节的url
def get_content_url(url):
    chapter=analysis_url(url)
    title=chapter.h1.get_text()
    content=chapter.find_all('div',id='content')[0].get_text()
    contents=title+'\n'+content
    return contents
  
def get_content(url):
    (story_name,chapter_url)=get_chapter_url(url)
    flag=True
    count=1
    for c in chapter_url:
        loading=count/len(chapter_url)*100
        print('%s 下载进度：%0.2f %%'%(story_name,loading))
        contents=get_content_url(c)
        f = open('C:/Users/ts_data/Desktop/'+story_name,'a+',encoding = 'utf-8')#a+:追加模式（在已有的文本后面写入内容）
        f.write(contents+'\n'*3)#'\n'换行写入
        f.close()
        count=count+1
        delay=random.random() #随机延时0-1s更能应对反爬
        time.sleep(delay)
# get_content(url)
print('**********************************************')

def main(url,j):
    book_url=get_book_url(url)
    for i in book_url[j:4:2]:#筛选小说数;
        get_content(i)
        print("线程名字：%s"%self.name)
    
 #多线程爬虫
class myThread(threading.Thread):
    def __init__(self,threadID,name,url):
        threading.Thread.__init__(self) #调用父类的构造函数 
        self.threadID=threadID
        self.name=name
        self.counter=url
    def run(self):
        print('开始线程：'+self.name)
        #获取锁，用于线程同步
        threading.Lock().acquire()#————————————第二步：线程同步（锁）
        main(url,self.counter)
        #释放锁，开启下个线程
        threading.Lock().release()#————————————第二步：线程同步（锁）
        print('结束线程：'+self.name)          
 
 start=time.clock()
threads=[]                 #————————————第二步：线程同步（锁）

#创建线程
thread1=myThread(1,'偶数列小说',0)
thread2=myThread(2,'奇数列小说',1)
#开始线程
thread1.start()
thread2.start()

#添加新线程到线程列表;
threads.append(thread1) #————————————第二步：线程同步（锁）
threads.append(thread2) #————————————第二步：线程同步（锁）
#等待所有线程完成;
for t in threads:       #————————————第二步：线程同步（锁）
    t.join()
print('运行时间:%.03f seconds'%(time.clock()-start))
print('退出线程')
