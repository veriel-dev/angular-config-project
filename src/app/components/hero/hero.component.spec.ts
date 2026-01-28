import { ComponentFixture, TestBed } from '@angular/core/testing';
import { HeroComponent } from './hero.component';

describe('HeroComponent', () => {
  let component: HeroComponent;
  let fixture: ComponentFixture<HeroComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [HeroComponent]
    }).compileComponents();

    fixture = TestBed.createComponent(HeroComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should have a headline', () => {
    expect(component.headline).toBeTruthy();
    expect(component.headline.length).toBeGreaterThan(0);
  });

  it('should have a subheadline', () => {
    expect(component.subheadline).toBeTruthy();
    expect(component.subheadline.length).toBeGreaterThan(0);
  });

  it('should have CTA text and link', () => {
    expect(component.ctaText).toBe('Ver proyectos');
    expect(component.ctaLink).toBe('#projects');
  });

  it('should have secondary CTA text and link', () => {
    expect(component.secondaryCtaText).toBe('Contactar');
    expect(component.secondaryCtaLink).toBe('#contact');
  });

  it('should render headline in template', () => {
    const compiled = fixture.nativeElement as HTMLElement;
    expect(compiled.querySelector('h1')?.textContent).toContain(component.headline);
  });

  it('should render subheadline in template', () => {
    const compiled = fixture.nativeElement as HTMLElement;
    expect(compiled.querySelector('p')?.textContent).toContain(component.subheadline);
  });

  it('should render CTA buttons', () => {
    const compiled = fixture.nativeElement as HTMLElement;
    const links = compiled.querySelectorAll('a');
    expect(links.length).toBe(2);
  });
});
