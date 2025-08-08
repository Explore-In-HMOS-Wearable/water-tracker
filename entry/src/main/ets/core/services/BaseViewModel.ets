import { RouteService } from './RouteService';


export class BaseViewModel {
  routeService: RouteService = RouteService.instance();
}
