import { ComponentFixture, TestBed } from '@angular/core/testing';
import { FooterComponent } from './footer.component';

describe('FooterComponent', () => {
  let component: FooterComponent;
  let fixture: ComponentFixture<FooterComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [FooterComponent]
    }).compileComponents();

    fixture = TestBed.createComponent(FooterComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should have current year', () => {
    expect(component.currentYear).toBe(new Date().getFullYear());
  });

  it('should have company name', () => {
    expect(component.companyName).toBe('StudioLab');
  });

  it('should have 4 social links', () => {
    expect(component.socialLinks.length).toBe(4);
  });

  it('should have social links with required properties', () => {
    component.socialLinks.forEach(link => {
      expect(link.name).toBeTruthy();
      expect(link.url).toBeTruthy();
      expect(link.icon).toBeTruthy();
    });
  });

  it('should have 3 footer links', () => {
    expect(component.footerLinks.length).toBe(3);
  });

  it('should have footer links with required properties', () => {
    component.footerLinks.forEach(link => {
      expect(link.label).toBeTruthy();
      expect(link.href).toBeTruthy();
    });
  });

  it('should render copyright text', () => {
    const compiled = fixture.nativeElement as HTMLElement;
    expect(compiled.textContent).toContain(component.currentYear.toString());
    expect(compiled.textContent).toContain(component.companyName);
  });

  it('should render social links', () => {
    const compiled = fixture.nativeElement as HTMLElement;
    const socialLinks = compiled.querySelectorAll('a[target="_blank"]');
    expect(socialLinks.length).toBe(4);
  });

  it('should render footer links', () => {
    const compiled = fixture.nativeElement as HTMLElement;
    expect(compiled.textContent).toContain('Politica de privacidad');
    expect(compiled.textContent).toContain('Terminos de uso');
    expect(compiled.textContent).toContain('Cookies');
  });

  it('should render brand name', () => {
    const compiled = fixture.nativeElement as HTMLElement;
    expect(compiled.textContent).toContain('Studio');
    expect(compiled.textContent).toContain('Lab');
  });
});
