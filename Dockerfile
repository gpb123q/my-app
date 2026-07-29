# 使用 Nginx 作为基础镜像
FROM nginx:alpine

# 复制静态文件
COPY src/ /usr/share/nginx/html/

# 暴露端口
EXPOSE 80

# 启动 Nginx
CMD ["nginx", "-g", "daemon off;"]