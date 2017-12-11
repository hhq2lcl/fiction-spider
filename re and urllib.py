
import urllib.request
import urllib.parse
import re

url ='http://www.budejie.com/text/1'
req = urllib.request.Request(url)
    # 添加headers 使之看起来像浏览器在访问
req.add_header('User-Agent', 'Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 '
                                 '(KHTML, like Gecko) Chrome/52.0.2743.116 Safari/537.36')
response = urllib.request.urlopen(req)
    # 得到网页内容，注意必须使用decode()解码
html = response.read().decode('utf-8')
pattern = re.compile(r'<div class="j-r-list-c-desc">\s+(.*)\s+</div>')
result = re.findall(pattern, html)
for each in result:
        # 如果某个段子里有<br />
        if '<br />' in each:
            # 替换成换行符并输出
            new_each = re.sub(r'<br />', '\n', each)
            print(new_each)
        # 没有就照常输出
        else:
            print(each)



from bs4 import BeautifulSoup
import re
import sys
import urllib.request   #导入urllib库的request模块

#指定要抓取的网页url，必须以http开头的
url='http://blog.csdn.net/u014453898/article/details/548#48707'
#模拟浏览器
headers={'User-Agent':'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.87 Safari/537.36'}
#调用 urlopen（）从服务器获取网页响应（respone），其返回的响应是一个实例
respone=urllib.request.urlopen(url)
#调用返回响应示例中的read（）函数，即可以读取html，但需要进行解码，
#具体解码写什么，要在你要爬取的网址右键，查看源代码;如‘utf-8’
html=respone.read().decode('utf-8')
# print(respone.info())——info()获取编码方式 #
urllib.request.urlretrieve(url,'./html_doc.txt')
