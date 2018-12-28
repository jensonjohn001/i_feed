class Feed {
  final String status;
  final List<Article> articles;

  Feed({
    this.status,
    this.articles
  });

  factory Feed.fromJson(Map<String, dynamic> parsedJson){
    var list = parsedJson['articles'] as List;
    print(list.runtimeType);
    List<Article> articlesList = list.map((i) => Article.fromJson(i)).toList();

    return Feed(
        status:parsedJson['status'],
        articles:articlesList
    );
  }

}

class Article {
  final String title;
  final String description, urlToImage, url, publishedAt;

  Article({
    this.title,
    this.description,
    this.urlToImage,
    this.url,
    this.publishedAt,
  });

  factory Article.fromJson(Map<String, dynamic> jsonData) {
    return Article(
      title: jsonData['title'],
      description: jsonData['description'],
      urlToImage: jsonData['urlToImage'],
      url: jsonData['url'],
      publishedAt: jsonData['publishedAt'],
    );
  }
}
