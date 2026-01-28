import { Component } from '@angular/core';
import { environment } from '../../../environments/environment';

interface SocialLink {
  name: string;
  url: string;
  icon: string;
}

interface FooterLink {
  label: string;
  href: string;
}

@Component({
  selector: 'app-footer',
  templateUrl: './footer.component.html',
})
export class FooterComponent {
  currentYear = new Date().getFullYear();
  companyName = 'StudioDev';
  envName = environment.envName;

  socialLinks: SocialLink[] = [
    { name: 'Twitter', url: 'https://twitter.com', icon: 'twitter' },
    { name: 'LinkedIn', url: 'https://linkedin.com', icon: 'linkedin' },
    { name: 'GitHub', url: 'https://github.com', icon: 'github' },
    { name: 'Instagram', url: 'https://instagram.com', icon: 'instagram' },
  ];

  footerLinks: FooterLink[] = [
    { label: 'Politica de privacidad', href: '#' },
    { label: 'Terminos de uso', href: '#' },
    { label: 'Cookies', href: '#' },
  ];
}
