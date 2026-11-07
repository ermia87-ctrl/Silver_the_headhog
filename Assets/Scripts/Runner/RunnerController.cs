using UnityEngine;

namespace PersianRunner
{
    [RequireComponent(typeof(CharacterController))]
    public sealed class RunnerController : MonoBehaviour
    {
        [SerializeField] float forwardSpeed = 12f;
        [SerializeField] float laneWidth = 2.4f;
        [SerializeField] float laneChangeSpeed = 12f;
        [SerializeField] float jumpHeight = 2.2f;
        [SerializeField] float gravity = -24f;
        CharacterController controller;
        int lane = 1;
        float verticalVelocity;
        Vector2 touchStart;
        bool trackingTouch;

        void Awake() => controller = GetComponent<CharacterController>();

        void Update()
        {
            ReadInput();
            float targetX = (lane - 1) * laneWidth;
            float x = Mathf.MoveTowards(transform.position.x, targetX, laneChangeSpeed * Time.deltaTime);
            if (controller.isGrounded && verticalVelocity < 0) verticalVelocity = -2f;
            verticalVelocity += gravity * Time.deltaTime;
            Vector3 motion = new Vector3((x - transform.position.x) / Mathf.Max(Time.deltaTime, .001f), verticalVelocity, forwardSpeed);
            controller.Move(motion * Time.deltaTime);
        }

        void ReadInput()
        {
            if (Input.GetKeyDown(KeyCode.LeftArrow) || Input.GetKeyDown(KeyCode.A)) ChangeLane(-1);
            if (Input.GetKeyDown(KeyCode.RightArrow) || Input.GetKeyDown(KeyCode.D)) ChangeLane(1);
            if (Input.GetKeyDown(KeyCode.Space) || Input.GetKeyDown(KeyCode.UpArrow)) Jump();
            if (Input.touchCount == 0) { trackingTouch = false; return; }
            Touch t = Input.GetTouch(0);
            if (t.phase == TouchPhase.Began) { touchStart = t.position; trackingTouch = true; }
            if (trackingTouch && (t.phase == TouchPhase.Ended || t.phase == TouchPhase.Canceled))
            {
                Vector2 delta = t.position - touchStart;
                if (delta.magnitude > 55f)
                {
                    if (Mathf.Abs(delta.x) > Mathf.Abs(delta.y)) ChangeLane(delta.x > 0 ? 1 : -1);
                    else if (delta.y > 0) Jump();
                }
                trackingTouch = false;
            }
        }

        public void ChangeLane(int direction) => lane = Mathf.Clamp(lane + direction, 0, 2);
        public void Jump()
        {
            if (controller.isGrounded) verticalVelocity = Mathf.Sqrt(jumpHeight * -2f * gravity);
        }
    }
}