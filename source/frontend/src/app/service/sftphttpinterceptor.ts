import { Injectable, Inject } from '@angular/core';
import { tap } from 'rxjs/operators';
import {
  HttpRequest,
  HttpHandler,
  HttpEvent,
  HttpInterceptor,
  HttpResponse,
  HttpErrorResponse,
  HttpXsrfTokenExtractor,
  HttpHeaders,
} from '@angular/common/http';
import { Observable } from 'rxjs';
import { DOCUMENT } from '@angular/common';

@Injectable()
export class MyInterceptor implements HttpInterceptor {
  constructor(
    @Inject(DOCUMENT) private doc: any,
    private tokenExtractor: HttpXsrfTokenExtractor
  ) {}
  //function which will be called for all http calls
  intercept(
    request: HttpRequest<any>,
    next: HttpHandler
  ): Observable<HttpEvent<any>> {
    let headers = new HttpHeaders();

    // Add CSRF token from cookie
    let csrfToken = this.tokenExtractor.getToken() as string;
    const cookies = this.doc.cookie.split(';');
    cookies.forEach((element) => {
      const csrf = element.trim().split('=');
      if (csrf[0] === 'csrf_access_token') {
        csrfToken = csrf[1];
      }
    });
    if (csrfToken !== null) {
      headers = headers.set('X-CSRF-TOKEN', csrfToken);
    }

    // Add Basic Auth header from localStorage if credentials exist
    const username = localStorage.getItem('username');
    const password = localStorage.getItem('password'); // Assuming password is stored, though ftp.service only shows getting username/ftpURL

    // Check if username and password exist before adding the header
    if (username && password) {
      const combined = username + ' ' + password;
      const basicAuth = 'Basic ' + btoa(combined.replace(/['"]+/g, ''));
      headers = headers.set('Authorization', basicAuth);
    } else if (username && !password && request.url.includes('/api/authenticate')) {
       // Special case for initial authentication if password isn't stored
       // This part might need adjustment based on how password is actually handled
       // For now, let the original request pass through for /api/authenticate if only username is found
       // Or potentially extract password from request body if applicable for this specific call?
       // Let's assume for now that if password isn't in local storage, we don't add the header
       // unless it's the authenticate call itself which constructs it in the service.
       // The ftp.service.ts already handles Basic Auth for /api/authenticate, so we don't need to duplicate here.
    } else if (username && password) {
       // If we have both, add the header (already covered above)
       const combined = username + ' ' + password;
       const basicAuth = 'Basic ' + btoa(combined.replace(/['"]+/g, ''));
       headers = headers.set('Authorization', basicAuth);
    }


    // Clone the request with the new headers if any were added
    if (headers.keys().length > 0) {
       const requestToForward = request.clone({ headers: headers });
       return next.handle(requestToForward);
    } else {
       // If no headers were added (e.g., no CSRF, no stored credentials), forward the original request
       return next.handle(request);
    }


  }
}
