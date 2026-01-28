import { ComponentFixture, TestBed } from '@angular/core/testing';
import { ServicesComponent } from './services.component';

describe('ServicesComponent', () => {
  let component: ServicesComponent;
  let fixture: ComponentFixture<ServicesComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ServicesComponent]
    }).compileComponents();

    fixture = TestBed.createComponent(ServicesComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should have section title', () => {
    expect(component.sectionTitle).toBe('Nuestros Servicios');
  });

  it('should have section subtitle', () => {
    expect(component.sectionSubtitle).toBeTruthy();
    expect(component.sectionSubtitle.length).toBeGreaterThan(0);
  });

  it('should have 4 services', () => {
    expect(component.services.length).toBe(4);
  });

  it('should have services with required properties', () => {
    component.services.forEach(service => {
      expect(service.icon).toBeTruthy();
      expect(service.title).toBeTruthy();
      expect(service.description).toBeTruthy();
    });
  });

  it('should render section title in template', () => {
    const compiled = fixture.nativeElement as HTMLElement;
    expect(compiled.querySelector('h2')?.textContent).toContain(component.sectionTitle);
  });

  it('should render all service cards', () => {
    const compiled = fixture.nativeElement as HTMLElement;
    const cards = compiled.querySelectorAll('.grid > div');
    expect(cards.length).toBe(4);
  });

  it('should render service titles', () => {
    const compiled = fixture.nativeElement as HTMLElement;
    const titles = compiled.querySelectorAll('h3');
    expect(titles.length).toBe(4);
  });
});
