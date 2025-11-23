export class RouteService {
  static _instance: RouteService;
  baseRoute: string = '';
  routeStack: string[] = [this.baseRoute];
  argument?: string | number | object = '';

  public init(params: InitParams) {
    this.baseRoute = params.baseRoute ?? `pages/Index`;
  }

  static instance() {
    if (!RouteService._instance) {
      RouteService._instance = new RouteService();
    }
    return RouteService._instance;
  }
}

export class InitParams {
  baseRoute?: string;
}