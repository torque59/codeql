import java

/**
 * Play MVC Framework HTTP Request Header
 *
 * @description Member of play.mvc.HTTP. Gets the play.mvc.HTTP$RequestHeader class/interface
 */
class PlayMVCHTTPRequestHeader extends RefType {
  PlayMVCHTTPRequestHeader() { this.hasQualifiedName("play.mvc", "Http$RequestHeader") }
}

/**
 * Play Framework HTTP$RequestHeader Methods
 *
 * @description Gets the methods of play.mvc.HTTP$RequestHeader like - headers, getQueryString, getHeader, uri
 * (https://www.playframework.com/documentation/2.6.0/api/java/play/mvc/Http.RequestHeader.html)
 */
class PlayHTTPRequestHeaderMethods extends Method {
  PlayHTTPRequestHeaderMethods() { this.getDeclaringType() instanceof PlayMVCHTTPRequestHeader }
}
