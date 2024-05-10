extends HttpRouter
class_name MainRouter

func handle_get(_request: HttpRequest, response: HttpResponse) -> void:
	response.send(200, "Lan-Jet is alive!")
